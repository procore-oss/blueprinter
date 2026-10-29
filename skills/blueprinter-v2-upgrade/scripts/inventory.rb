# frozen_string_literal: true

#
# Inventory every Blueprint in an application, for planning a V1 -> V2 migration.
#
# Writes a JSON report to stdout describing each Blueprint's file, ancestry, views, fields, and
# — most usefully — which V1-only features it actually uses. Progress and warnings go to stderr,
# so redirecting stdout gives you clean JSON.
#
# Usage
# -----
#
#   Rails:
#     bin/rails runner path/to/inventory.rb > inventory.json
#
#   Non-Rails (adjust the require to whatever loads your Blueprints):
#     bundle exec ruby -r./config/environment path/to/inventory.rb > inventory.json
#
#   Specific files only, when the app can't boot:
#     bundle exec ruby -r blueprinter -r ./app/blueprints/widget_blueprint.rb path/to/inventory.rb
#
# Notes
# -----
#
# Blueprints are found by walking ObjectSpace, so they have to be loaded first. Under Rails this
# script calls `eager_load!` for you. Anything still lazily autoloaded won't appear.
#

require 'json'

module BlueprinterInventory
  # V1 extractors that are Blueprinter's own defaults. A field carrying one of these is restating
  # the default, not customizing anything, so it isn't reported as a V1 feature.
  BUILTIN_EXTRACTORS = %w[
    Blueprinter::AutoExtractor
    Blueprinter::AssociationExtractor
    Blueprinter::BlockExtractor
    Blueprinter::HashExtractor
    Blueprinter::PublicSendExtractor
  ].freeze

  V1_COND_ARITY = 3

  # Field options reported verbatim (via inspect) when present.
  INSPECTED_OPTS = %i[name datetime_format default default_if exclude_if_nil options].freeze

  # V1 global settings that V2 ignores, paired with a test for whether the app actually set one.
  # Anything listed here silently stops applying the moment a Blueprint moves to V2.
  MIGRATION_NOTES = {
    'sort_fields_by is not :definition — V2 uses definition order, so JSON key order will change' =>
      ->(c) { c.sort_fields_by != :definition },
    'field_default is set — V2 ignores it; port with `set :default`' =>
      ->(c) { !c.field_default.nil? },
    'association_default is set — V2 ignores it; port with `set :default`' =>
      ->(c) { !c.association_default.nil? },
    'global if is set — V2 ignores it; port with `set :if`' =>
      ->(c) { !c.if.nil? },
    'global unless is set — V2 ignores it; port with `set :unless`' =>
      ->(c) { !c.unless.nil? },
    'datetime_format is set — V2 ignores it; port with `format Date/Time/DateTime`' =>
      ->(c) { !c.datetime_format.nil? },
    'default_transformers is set — V2 ignores it; port with LegacyTransformer' =>
      ->(c) { c.default_transformers.any? },
    'extractor_default is customized — port with LegacyOptions + `set :extractor`' =>
      ->(c) { !BUILTIN_EXTRACTORS.include?(c.extractor_default.to_s) },
    'a custom JSON generator is set — V2 ignores it; port with MultiJson or an around_result extension' =>
      ->(c) { c.generator.to_s != 'JSON' || c.method != :generate },
    'custom_array_like_classes is set — V2 ignores it; use render_collection at call sites' =>
      ->(c) { c.custom_array_like_classes.any? },
    'global extensions are set — V2 ignores config.extensions, and V1 pre_render hooks never run in V2' =>
      ->(c) { c.extensions.any? }
  }.freeze

  # V1-only field features, keyed by the label reported in `v1_features`.
  FIELD_FEATURES = {
    'name_option' => ->(f) { f[:opt_name] },
    'extractor_option' => ->(f) { f[:extractor] },
    'datetime_format' => ->(f) { f[:opt_datetime_format] },
    'dynamic_association_options' => ->(f) { f[:opt_options] },
    'default_if' => ->(f) { f[:opt_default_if] },
    'association_view_option' => ->(f) { f[:view] },
    'field_block' => ->(f) { f[:block] && !f[:association] },
    'v1_conditional' => lambda { |f|
      [f[:opt_if], f[:opt_unless]].compact.any? { |c| c.include?('V1 style') || c.include?('CLASS method') }
    }
  }.freeze

  class << self
    def run
      abort 'Blueprinter is not loaded. Require your application first.' unless defined?(::Blueprinter)

      eager_load!
      v1, v2 = all_blueprints

      report = {
        blueprinter_version: version,
        v2_available: defined?(::Blueprinter::V2::Base) ? true : false,
        configuration: configuration,
        counts: { v1: v1.size, v2: v2.size },
        blueprints: (v1 + v2).map { |klass| describe(klass) }.sort_by { |b| b[:name].to_s }
      }

      puts JSON.pretty_generate(report)
      warn "Found #{v1.size} V1 Blueprint(s) and #{v2.size} V2 Blueprint(s)."
    end

    private

    def eager_load!
      return unless defined?(::Rails) && ::Rails.respond_to?(:application) && ::Rails.application

      ::Rails.application.eager_load!
      warn 'Eager-loaded the Rails application.'
    rescue StandardError => e
      warn "Could not eager-load: #{e.class}: #{e.message}. Results may be incomplete."
    end

    def version
      require 'blueprinter/version'
      ::Blueprinter::VERSION
    rescue StandardError, LoadError
      'unknown'
    end

    def all_blueprints
      v1 = []
      v2 = []
      ObjectSpace.each_object(Class) do |klass|
        v1 << klass if v1?(klass)
        v2 << klass if v2?(klass)
      end
      # V2 views are anonymous subclasses created on demand; only report real, named Blueprints.
      [v1, v2.reject { |k| k.name.nil? }]
    end

    def v1?(klass)
      klass < ::Blueprinter::Base
    rescue StandardError
      false
    end

    def v2?(klass)
      defined?(::Blueprinter::V2::Base) && klass < ::Blueprinter::V2::Base
    rescue StandardError
      false
    end

    def configuration
      config = ::Blueprinter.configuration
      {
        sort_fields_by: config.sort_fields_by.inspect,
        field_default: config.field_default.inspect,
        association_default: config.association_default.inspect,
        if: config.if.inspect,
        unless: config.unless.inspect,
        datetime_format: config.datetime_format.inspect,
        default_transformers: config.default_transformers.map(&:to_s),
        extractor_default: config.extractor_default.to_s,
        generator: config.generator.to_s,
        method: config.method.inspect,
        custom_array_like_classes: config.custom_array_like_classes.map(&:to_s),
        extensions: config.extensions.map { |e| e.class.to_s },
        # Flags the settings whose V1 default differs from V2's behavior, so they're easy to spot.
        changes_output_on_migration: changed_defaults(config)
      }
    rescue StandardError => e
      { error: "#{e.class}: #{e.message}" }
    end

    def changed_defaults(config)
      MIGRATION_NOTES.filter_map { |note, applies| note if applies.call(config) }
    end

    def describe(klass)
      base = {
        name: klass.name || '(anonymous)',
        anonymous: klass.name.nil?,
        api: v2?(klass) ? 'v2' : 'v1',
        file: source_location(klass),
        superclass: klass.superclass.name || '(anonymous)',
        ancestry: blueprint_ancestry(klass),
        subclasses: subclasses_of(klass)
      }
      return base if base[:api] == 'v2'

      views = describe_views(klass)
      base.merge(
        v1_features: features(klass, views).sort,
        views: views
      )
    rescue StandardError => e
      { name: klass.name || '(anonymous)', error: "#{e.class}: #{e.message}" }
    end

    def source_location(klass)
      return nil if klass.name.nil?

      loc = Object.const_source_location(klass.name)
      loc && loc.first ? "#{relative(loc[0])}:#{loc[1]}" : nil
    rescue StandardError
      nil
    end

    def relative(path)
      root = defined?(::Rails) && ::Rails.respond_to?(:root) && ::Rails.root ? ::Rails.root.to_s : Dir.pwd
      path.start_with?(root) ? path.sub("#{root}/", '') : path
    end

    # Blueprint ancestors between this class and the base class. A V2 Blueprint can't inherit from
    # a V1 one, so every entry here needs a V2 counterpart before this class can be converted.
    def blueprint_ancestry(klass)
      chain = []
      current = klass.superclass
      while current && current != ::Blueprinter::Base &&
            !(defined?(::Blueprinter::V2::Base) && current == ::Blueprinter::V2::Base)
        chain << (current.name || '(anonymous)')
        current = current.superclass
      end
      chain
    end

    # Converting a Blueprint breaks any V1 subclass of it, so these have to be converted too.
    def subclasses_of(klass)
      found = []
      ObjectSpace.each_object(Class) do |other|
        found << (other.name || '(anonymous)') if other != klass && other.superclass == klass
      end
      found.sort
    end

    # V1 copies a parent's fields, transformers, and included views down into each subclass, so a
    # Blueprint reports all of them as its own. Subtract the parent's to show what this class
    # actually declares — that's the difference between "needs work" and "nothing to do here".
    def describe_views(klass)
      klass.view_collection.views.each_with_object({}) do |(view_name, view), out|
        out[view_name] = describe_view(view, inherited_from_parent(klass, view_name))
      end
    end

    def describe_view(view, inherited)
      own, shared = view.fields.each_value.partition { |f| !inherited[:fields].include?(f.name) }
      {
        own_fields: own.map { |f| describe_field(f) },
        inherited_field_count: shared.size,
        include_views: (view.included_view_names - inherited[:includes]).map(&:to_s),
        excludes: view.excluded_field_names.map(&:to_s),
        transformers: (view.view_transformers - inherited[:transformers]).map(&:to_s),
        inherited_transformers: inherited[:transformers].map(&:to_s)
      }
    end

    def inherited_from_parent(klass, view_name)
      view = parent_view(klass, view_name)
      return { fields: [], includes: [], transformers: [] } if view.nil?

      { fields: view.fields.keys, includes: view.included_view_names, transformers: view.view_transformers }
    end

    def parent_view(klass, view_name)
      parent = klass.superclass
      return nil unless v1?(parent)

      parent.view_collection.views[view_name]
    rescue StandardError
      nil
    end

    def describe_field(field)
      opts = field.options || {}
      base = {
        name: field.name.to_s,
        source: field.method.to_s,
        association: !opts[:association].nil?,
        block: !opts[:block].nil?
      }
      base.merge(field_target(field, opts), field_opts(opts))
    end

    # Where the field's value comes from: an associated Blueprint/view, or a custom extractor.
    def field_target(field, opts)
      out = {}
      out[:blueprint] = opts[:blueprint].to_s if opts[:blueprint]
      out[:view] = opts[:view].to_s if opts[:view] && opts[:view] != :default
      out[:extractor] = field.extractor.class.to_s unless builtin_extractor?(field.extractor)
      out
    end

    def field_opts(opts)
      out = {}
      INSPECTED_OPTS.each { |key| out[:"opt_#{key}"] = opts[key].inspect if opts.key?(key) }
      %i[if unless].each { |key| out[:"opt_#{key}"] = describe_conditional(opts[key]) if opts.key?(key) }
      out
    end

    def builtin_extractor?(extractor)
      name = extractor.is_a?(Class) ? extractor.to_s : extractor.class.to_s
      BUILTIN_EXTRACTORS.include?(name)
    end

    def describe_conditional(cond)
      case cond
      when Proc then "Proc(arity #{cond.arity}) — #{v1_style_proc?(cond) ? 'V1 style' : 'V2 style'}"
      when Symbol, String then "method :#{cond} — V1 resolves this as a CLASS method"
      when nil then 'nil (opts out of the global if/unless)'
      else cond.inspect
      end
    end

    def v1_style_proc?(proc)
      types = proc.parameters.map(&:first)
      return types.count(:req) <= V1_COND_ARITY if types.include?(:rest)

      V1_COND_ARITY.between?(types.count(:req), types.count(:req) + types.count(:opt))
    end

    # Which V1-only features this Blueprint *itself* declares. This is the signal for how much
    # work it is; features it merely inherits are the parent's problem.
    def features(_klass, views)
      found = []
      found << 'identifier' if views.dig(:identifier, :own_fields)&.any?

      views.each_value do |view|
        found << 'include_view' if view[:include_views].any?
        found << 'transform' if view[:transformers].any?
        view[:own_fields].each { |field| found.concat(field_features(field)) }
      end
      found.uniq
    end

    def field_features(field)
      FIELD_FEATURES.filter_map { |feature, present| feature if present.call(field) }
    end
  end
end

BlueprinterInventory.run
