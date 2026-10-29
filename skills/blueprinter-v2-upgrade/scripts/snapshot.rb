# frozen_string_literal: true

#
# Capture rendered Blueprint output to a directory of JSON files, for before/after comparison
# across a V1 -> V2 migration.
#
# The whole point is that the *same fixtures file* works before and after conversion: this script
# renders through whichever API each Blueprint currently has (V1 `render_as_hash(obj, view:)` or
# V2 `Blueprint[view].render(obj).to_hash`). So you capture a baseline, convert, re-run with the
# same fixtures, and diff.
#
# Usage
# -----
#
#   bin/rails runner path/to/snapshot.rb FIXTURES_FILE OUTPUT_DIR
#
#   # before converting
#   bin/rails runner skills/.../snapshot.rb bp_fixtures.rb tmp/bp-before
#   # ...convert...
#   bin/rails runner skills/.../snapshot.rb bp_fixtures.rb tmp/bp-after
#   python3 skills/.../compare_snapshots.py tmp/bp-before tmp/bp-after
#
# Fixtures file
# -------------
#
# A Ruby file whose last expression is an Array of Hashes:
#
#   WIDGET = { name: 'Widget', description: 'A widget', category: { name: 'Tools' }, parts: [] }
#
#   [
#     {
#       blueprint: WidgetBlueprint,
#       views: [:default, :extended],
#       options: { current_user: nil },
#       samples: {
#         'full'    => -> { WIDGET },
#         'nils'    => -> { { name: 'Widget', description: nil, category: nil, parts: nil } },
#         'empties' => -> { { name: '', description: '', category: {}, parts: [] } },
#         'list'    => -> { [WIDGET, WIDGET] }
#       }
#     }
#   ]
#
# `views` and `options` are optional; `views` defaults to every view the Blueprint defines.
#
# Samples must be deterministic. Hand-built Hashes and Structs are ideal — Blueprinter renders
# anything that responds to the right methods, so you rarely need real models. `Model.find(123)`
# is fine. Random factory data is not: it fills the diff with noise and hides real changes.
#
# Cover a fully-populated object, one with nil associations and nil/empty values, and an empty
# collection. That's where V1 and V2 diverge.
#

require 'json'
require 'fileutils'

module BlueprinterSnapshot
  class << self
    def run(argv)
      fixtures_path, output_dir = argv
      usage! unless fixtures_path && output_dir
      abort "Fixtures file not found: #{fixtures_path}" unless File.exist?(fixtures_path)
      abort 'Blueprinter is not loaded. Require your application first.' unless defined?(::Blueprinter)

      specs = load_fixtures(fixtures_path)
      FileUtils.mkdir_p(output_dir)

      manifest = []
      errors = 0

      specs.each do |spec|
        blueprint = spec.fetch(:blueprint)
        options = spec[:options] || {}
        views = spec[:views] || default_views(blueprint)

        views.each do |view|
          spec.fetch(:samples).each do |sample_name, sample|
            key = "#{blueprint_label(blueprint)}.#{view}.#{sample_name}"
            result = capture(blueprint, view, sample, options)
            errors += 1 if result.is_a?(Hash) && result.key?('__error__')
            File.write(File.join(output_dir, "#{filename(key)}.json"), JSON.pretty_generate(result))
            manifest << { key: key, api: api_of(blueprint), file: "#{filename(key)}.json" }
          end
        end
      end

      File.write(File.join(output_dir, '_manifest.json'), JSON.pretty_generate(manifest))
      warn "Wrote #{manifest.size} snapshot(s) to #{output_dir}."
      warn "#{errors} render(s) raised — see the __error__ entries." if errors.positive?
    end

    private

    def usage!
      abort 'Usage: snapshot.rb FIXTURES_FILE OUTPUT_DIR'
    end

    def load_fixtures(path)
      specs = eval(File.read(path), TOPLEVEL_BINDING, path) # rubocop:disable Security/Eval
      abort "#{path} must evaluate to an Array of Hashes" unless specs.is_a?(Array)
      specs
    end

    # Render through whichever API the Blueprint currently has, so one fixtures file serves both
    # sides of the migration.
    def capture(blueprint, view, sample, options)
      object = sample.respond_to?(:call) ? sample.call : sample
      if v2?(blueprint)
        blueprint[view].render(object, options).to_hash
      else
        blueprint.render_as_hash(object, options.merge(view: view))
      end
    rescue StandardError => e
      { '__error__' => "#{e.class}: #{e.message}" }
    end

    def default_views(blueprint)
      if v2?(blueprint)
        [:default, *blueprint.reflections.keys].uniq
      else
        blueprint.view_collection.views.keys
      end
    rescue StandardError
      [:default]
    end

    def v2?(blueprint)
      defined?(::Blueprinter::V2::Base) && blueprint < ::Blueprinter::V2::Base
    end

    def api_of(blueprint)
      v2?(blueprint) ? 'v2' : 'v1'
    end

    def blueprint_label(blueprint)
      blueprint.name || blueprint.to_s
    end

    def filename(key)
      key.gsub(/[^A-Za-z0-9._-]/, '_')
    end
  end
end

BlueprinterSnapshot.run(ARGV)
