# frozen_string_literal: true

require 'etc'
require 'fileutils'
require 'json'
require 'time'
require_relative 'markdown'

module PerfBench
  # Collects results, prints the markdown summary, and writes the JSON file.
  class Report
    # Outside tmp/, which the generator specs empty. OUT_DIR overrides it.
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
        git_dirty: !`git status --porcelain --untracked-files=no 2>/dev/null`.strip.empty?,
        platform: RUBY_PLATFORM,
        features: PerfBench::FEATURES.keys.to_h { |f| [f, PerfBench.feature?(f)] },
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
                          load_average: Report.load_average, results:, skipped: sweep.skipped }
    end

    def add_profile(profile) = @data[:profiles] << profile

    def self.out_dir = File.expand_path(ENV.fetch('OUT_DIR', DEFAULT_OUT_DIR))

    def self.mode = defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled? ? 'yjit' : 'interp'

    # @return [String | nil] the newest results file written under the same YJIT mode, other than `except`
    def self.latest(except: nil)
      Dir[File.join(out_dir, "perf-*-#{mode}.json")].reject { |f| f == except }.max_by { |f| File.mtime(f) }
    end

    # Writes the JSON and the full markdown report side by side.
    #
    # @return [Array<String>] the JSON path and the markdown path
    def finish!
      @data[:environment][:load_average_end] = Report.load_average
      @data[:environment][:finished_at] = Time.now.utc.iso8601
      FileUtils.mkdir_p(Report.out_dir)
      base = File.join(Report.out_dir, "perf-#{Time.now.strftime('%Y%m%d-%H%M%S')}-#{Report.mode}")
      File.write("#{base}.json", JSON.pretty_generate(finite(@data)))
      File.write("#{base}.md", "#{markdown}\n")
      ["#{base}.json", "#{base}.md"]
    end

    def markdown
      out = [header]
      @data[:sweeps].each { |sweep| out << sweep_markdown(sweep) }
      @data[:profiles].each { |profile| out << profile_markdown(profile) }
      out << skipped_markdown
      out.compact.join("\n\n")
    end

    # What the terminal shows: one line of environment and anything skipped. The tables are in the markdown file.
    def summary
      env = @data[:environment]
      dirty = ' with uncommitted changes' if env[:git_dirty]
      line = "#{ruby_short(env)}, YJIT #{env[:yjit] ? 'on' : 'off'}, blueprinter #{env[:blueprinter]} at " \
             "#{env[:git_commit]}#{dirty}, load #{env[:load_average_start].first} to " \
             "#{Array(env[:load_average_end]).first}"
      [line, skipped_markdown].compact.join("\n\n")
    end

    def ruby_short(env) = env[:ruby].to_s[/\Aruby \S+/] || env[:ruby].to_s

    COLUMNS = ['ms', 'IQR', 'CPU ms', 'alloc/obj', 'GC%'].freeze

    # @return [Float | nil] (p75 - p25) / median of the wall-time batch means
    def self.iqr_share(measured, prefix = '')
      median, p25, p75 = measured.values_at(:"#{prefix}median_ms", :"#{prefix}p25_ms", :"#{prefix}p75_ms")
      (p75 - p25) / median if median&.positive? && p25 && p75
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
      missing = env[:features].reject { |_, on| on }.keys
      <<~MD.strip
        # Blueprinter render benchmark

        - #{env[:ruby]}, YJIT #{env[:yjit] ? 'on' : 'off'}, #{env[:cpus]} CPUs
        - blueprinter #{env[:blueprinter]} at #{env[:git_commit]}#{' with uncommitted changes' if env[:git_dirty]}#{" (not installed: #{missing.join(', ')})" unless missing.empty?}
        - Load average at start #{env[:load_average_start].join(' ')}, at end #{Array(env[:load_average_end]).join(' ')}
        - Samples: up to #{knobs[:samples]} batches of renders lasting at least #{knobs[:sample_ms]} ms each, within #{knobs[:budget_s]} s; seed #{knobs[:seed]}
        - Times are per render, medians over batch means. `IQR` is the interquartile range of those means as a share of the median: the run's own noise. `CPU` is thread CPU time.
        - `alloc/obj` is objects allocated per render (GC disabled during the count) divided by Hashes in the output. `GC%` is GC time as a share of wall time over a #{knobs[:gc_ms]} ms run.
      MD
    end

    def sweep_markdown(sweep)
      lines = ["## #{sweep[:name]}: #{sweep[:title]}", '', sweep[:description], '']
      results = sweep[:results]
      return (lines + custom_table(results)).join("\n") if results.is_a?(Hash)

      engines = results.flat_map { |r| r[:engines].keys }.uniq
      lines.concat(table(sweep[:title], engines, results))
      notes = results.flat_map do |r|
        n = r[:note] ? ["- #{r[:label]}: #{r[:note]}"] : []
        n + r[:excluded].map { |eng, why| "- #{r[:label]}: **#{eng} excluded**, #{why}" }
      end
      lines.push('', *notes) unless notes.empty?
      lines.join("\n")
    end

    def table(axis, engines, results)
      prefix = engines.size > 1
      head = [axis, 'objects']
      engines.each { |e| head.concat(COLUMNS.map { |c| prefix ? "#{e} #{c}" : c }) }
      rows = results.map do |r|
        [r[:label], r[:rendered_objects], *engines.flat_map { |e| cells(r[:engines][e]) }]
      end
      Markdown.table(head, rows)
    end

    def cells(measured)
      return ['n/a'] * COLUMNS.size unless measured

      [Markdown.num(measured[:median_ms]), Markdown.pct(Report.iqr_share(measured)), Markdown.num(measured[:cpu_median_ms]),
       Markdown.num(measured[:allocations_per_object]), Markdown.pct(measured[:gc][:gc_share])]
    end

    def custom_table(results)
      notes = Array(results[:notes]).map { |n| "- #{n}" }
      Markdown.table(results[:columns], results[:rows]) + (notes.empty? ? [] : ['', *notes])
    end

    def profile_markdown(profile)
      lines = ["## Allocation sites: #{profile[:scenario]}", '', profile[:description], '']
      profile[:engines].each do |name, sites|
        imemo = sites[:imemo].map { |type, n| "#{type} #{n}" }.join(', ')
        lines << "#{"**#{name}**: " if profile[:engines].size > 1}#{sites[:total]} objects per render, " \
                 "#{Markdown.num(sites[:per_object])} per rendered object; #{sites[:untracked]} not attributable to " \
                 "a site#{" (VM-internal: #{imemo})" unless imemo.empty?}."
        lines << ''
        rows = sites[:top].map { |s| [s[:site], s[:class], s[:count], Markdown.num(s[:per_object])] }
        lines.concat(Markdown.table(%w[site class objects per-object], rows))
        lines << ''
      end
      lines.join("\n")
    end
  end
end
