# frozen_string_literal: true

require 'etc'
require 'fileutils'
require 'json'
require 'time'

module EngineBench
  # Collects results, prints the markdown summary, and writes the JSON file.
  class Report
    # Outside tmp/, which `rake spec` empties. OUT_DIR overrides it.
    DEFAULT_OUT_DIR = File.expand_path('../../../benchmarks/results', __dir__)

    attr_reader :data

    def initialize(knobs)
      @data = { environment: Report.environment, knobs: knobs.to_h, sweeps: [], profiles: [] }
    end

    def self.environment
      {
        ruby: RUBY_DESCRIPTION,
        yjit: defined?(RubyVM::YJIT) ? RubyVM::YJIT.enabled? : false,
        rubyopt: ENV.fetch('RUBYOPT', ''),
        blueprinter: Blueprinter::VERSION,
        git_commit: `git rev-parse --short HEAD 2>/dev/null`.strip,
        platform: RUBY_PLATFORM,
        features: EngineBench::FEATURES.keys.to_h { |f| [f, EngineBench.feature?(f)] },
        cpus: Etc.nprocessors,
        load_average_start: load_average,
        started_at: Time.now.utc.iso8601
      }
    end

    def self.load_average
      if File.readable?('/proc/loadavg')
        File.read('/proc/loadavg').split.first(3).map(&:to_f)
      else
        `sysctl -n vm.loadavg 2>/dev/null`.scan(/[\d.]+/).first(3).map(&:to_f)
      end
    rescue StandardError
      []
    end

    def add_sweep(sweep, results)
      @data[:sweeps] << { name: sweep.name, title: sweep.title, description: sweep.description,
                          engines: sweep.engine_names, load_average: Report.load_average, results:,
                          skipped: sweep.skipped }
    end

    def add_profile(profile) = @data[:profiles] << profile

    def finish!
      @data[:environment][:load_average_end] = Report.load_average
      @data[:environment][:finished_at] = Time.now.utc.iso8601
      out_dir = File.expand_path(ENV.fetch('OUT_DIR', DEFAULT_OUT_DIR))
      FileUtils.mkdir_p(out_dir)
      mode = @data[:environment][:yjit] ? 'yjit' : 'interp'
      path = File.join(out_dir, "engines-#{Time.now.strftime('%Y%m%d-%H%M%S')}-#{mode}.json")
      File.write(path, JSON.pretty_generate(finite(@data)))
      path
    end

    def markdown
      out = [header]
      @data[:sweeps].each { |sweep| out << sweep_markdown(sweep) }
      @data[:profiles].each { |profile| out << profile_markdown(profile) }
      out << skipped_markdown
      out.compact.join("\n\n")
    end

    private

    def finite(value)
      case value
      when Hash then value.transform_values { |v| finite(v) }
      when Array then value.map { |v| finite(v) }
      when Float then value.finite? ? value : nil
      else value
      end
    end

    def skipped_markdown
      skipped = @data[:sweeps].flat_map { |sw| sw[:skipped].map { |s| "- #{sw[:name]} / #{s[:label]}: #{s[:reason]}" } }
      return if skipped.empty?

      ['## Skipped scenarios', '', *skipped].join("\n")
    end

    def header
      env = @data[:environment]
      knobs = @data[:knobs]
      <<~MD.strip
        # Blueprinter engine benchmark

        - #{env[:ruby]}, YJIT #{env[:yjit] ? 'on' : 'off'}, #{env[:cpus]} CPUs, blueprinter #{env[:blueprinter]} (#{env[:git_commit]})
        - Engines: #{engines_line(env)}
        - Load average at start #{env[:load_average_start].join(' ')}, at end #{Array(env[:load_average_end]).join(' ')}
        - Samples per engine: up to #{knobs[:samples]} (each a batch of renders lasting at least #{knobs[:sample_ms]} ms), budget #{knobs[:budget_s]} s, seed #{knobs[:seed]}
        - Times are per render. p95 is over per-batch means, so it shows batch-to-batch spread rather than single-render tails.
        - `alloc/obj` is objects allocated per render (GC disabled during the count) divided by Hashes in the output. `GC%` is GC time as a share of wall time over a #{knobs[:gc_ms]} ms run.
      MD
    end

    def engines_line(env)
      names = %w[V1] + (env[:features][:v2] ? %w[V2 V2+Legacy] : [])
      line = names.join(', ')
      missing = env[:features].reject { |_, on| on }.keys
      missing.empty? ? line : "#{line} (unavailable: #{missing.join(', ')})"
    end

    def sweep_markdown(sweep)
      lines = ["## #{sweep[:name]}: #{sweep[:title]}", '', sweep[:description], '']
      results = sweep[:results]
      return (lines + custom_table(results)).join("\n") if results.is_a?(Hash)

      engines = sweep[:engines]
      lines.concat(table(sweep[:title], engines, results))
      notes = results.flat_map do |r|
        n = r[:note] ? ["- #{r[:label]}: #{r[:note]}"] : []
        n + r[:excluded].map { |eng, why| "- #{r[:label]}: **#{eng} excluded**, #{why}" }
      end
      lines.push('', *notes) unless notes.empty?
      lines.join("\n")
    end

    def table(axis, engines, results)
      head = [axis, 'objects']
      engines.each { |e| head.push("#{e} ms", "#{e} p95", "#{e} alloc/obj", "#{e} GC%") }
      (engines - ['V1']).each { |e| head.push("#{e}/V1 time", "#{e}/V1 alloc") }
      rows = results.map do |r|
        row = [r[:label], r[:rendered_objects]]
        engines.each do |e|
          row.concat(cells(r[:engines][e]))
        end
        (engines - ['V1']).each { |e| row.concat(ratios(r[:engines]['V1'], r[:engines][e])) }
        row
      end
      md_table(head, rows)
    end

    def cells(measured)
      return ['n/a'] * 4 unless measured

      [num(measured[:median_ms]), num(measured[:p95_ms]), num(measured[:allocations_per_object]),
       pct(measured[:gc][:gc_share])]
    end

    def ratios(base, other)
      return %w[n/a n/a] unless base && other

      [ratio(other[:median_ms], base[:median_ms]), ratio(other[:allocations], base[:allocations])]
    end

    def custom_table(results)
      notes = Array(results[:notes]).map { |n| "- #{n}" }
      md_table(results[:columns], results[:rows]) + (notes.empty? ? [] : ['', *notes])
    end

    def profile_markdown(profile)
      lines = ["## Allocation sites: #{profile[:scenario]}", '', profile[:description], '']
      profile[:engines].each do |name, sites|
        imemo = sites[:imemo].map { |type, n| "#{type} #{n}" }.join(', ')
        lines << "**#{name}**: #{sites[:total]} objects per render, #{num(sites[:per_object])} per rendered object; " \
                 "#{sites[:untracked]} not attributable to a site#{" (VM-internal: #{imemo})" unless imemo.empty?}."
        lines << ''
        rows = sites[:top].map { |s| [s[:site], s[:class], s[:count], num(s[:per_object])] }
        lines.concat(md_table(%w[site class objects per-object], rows))
        lines << ''
      end
      lines.join("\n")
    end

    def md_table(head, rows)
      cells = ->(row) { row.map { |c| c.to_s.gsub('|', '\\|') }.join(' | ') }
      ["| #{cells.call(head)} |", "|#{head.map { ' --- |' }.join}", *rows.map { |r| "| #{cells.call(r)} |" }]
    end

    def ratio(a, b) = a && b&.positive? ? format('%.2fx', a.fdiv(b)) : 'n/a'

    def pct(value) = value ? format('%.0f%%', value * 100) : 'n/a'

    def num(value)
      return 'n/a' if value.nil?
      return value.to_s if value.is_a?(Integer)

      if value >= 100 then format('%.0f', value)
      elsif value >= 10 then format('%.1f', value)
      elsif value >= 0.1 then format('%.2f', value)
      else format('%.4f', value)
      end
    end
  end
end
