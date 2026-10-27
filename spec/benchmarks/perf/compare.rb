# frozen_string_literal: true

require 'json'
require 'rainbow'
require_relative 'markdown'
require_relative 'report'

module PerfBench
  # Compares a finished run with an earlier results file (BASELINE=path.json): for every scenario present in both,
  # the change in median wall time, median CPU time, and allocations per rendered object, plus whether the rendered
  # output changed. A time change is reported as within noise (`~`) when it is smaller than the larger of the two
  # runs' IQR-to-median ratios, since a difference that size shows up between batches of a single run.
  #
  # The report leads with the scenarios that changed; the full per-sweep tables follow, collapsed.
  class Compare
    MINUS = '−'
    # Allocation counts don't depend on load, but first-use caches can move a render by an object or two
    ALLOC_OBJECTS = 2
    # Below this many batches the IQR says little, so time changes get flagged on identical code
    MIN_SAMPLES = 10

    Row = Struct.new(:sweep, :title, :label, :engine, :before, :after, keyword_init: true) do
      def where = "#{sweep} / #{label}#{" (#{engine})" if engine != ENGINE}"

      def output_changed?
        before[:output_digest] && after[:output_digest] && before[:output_digest] != after[:output_digest]
      end

      def alloc_changed? = (after[:allocations].to_i - before[:allocations].to_i).abs > ALLOC_OBJECTS

      # @return [Float | nil] (after - before) / before for `median_ms` or `cpu_median_ms`, nil when either is missing
      def delta(prefix = '')
        b = before[:"#{prefix}median_ms"]
        a = after[:"#{prefix}median_ms"]
        (a - b) / b if b&.positive? && a
      end

      def beyond_noise?(prefix = '')
        d = delta(prefix)
        return false unless d

        noise = [Report.iqr_share(before, prefix), Report.iqr_share(after, prefix)].compact.max || 0
        d.abs > noise
      end

      def changed? = beyond_noise? || alloc_changed? || output_changed?
    end

    def initialize(baseline_path, current_path)
      @baseline = JSON.parse(File.read(baseline_path), symbolize_names: true)
      @current = JSON.parse(File.read(current_path), symbolize_names: true)
      @baseline_path = baseline_path
      @current_path = current_path
      @flags = []
      @rows = collect_rows
    end

    def markdown
      changed = @rows.select(&:changed?)
      faster, slower = @rows.select(&:beyond_noise?).partition { |r| r.delta.negative? }
      allocs = @rows.count(&:alloc_changed?)
      outputs = @rows.count(&:output_changed?)
      tally = "#{@rows.size} scenarios compared, #{changed.size} changed: " \
              "#{paint("#{faster.size} faster", :green, faster.size)} and " \
              "#{paint("#{slower.size} slower", :red, slower.size)} beyond noise, " \
              "#{paint("#{allocs} with a different allocation count", :yellow, allocs)}, " \
              "#{paint("#{outputs} with different output", :red, outputs)}."
      lines = ['# Comparison with baseline', '',
               "- Baseline: `#{@baseline_path}` (#{describe(@baseline[:environment])})",
               "- Current: `#{@current_path}` (#{describe(@current[:environment])})",
               "- #{tally}",
               '- Change is (current − baseline) / baseline. `~` marks a time change within noise. An allocation ' \
               "change counts when it is more than #{ALLOC_OBJECTS} objects per render."]
      warnings.each { |w| lines << paint("- **Warning:** #{w}", :yellow) }
      lines.push('', '## Changed', '', *changed_table(changed))
      lines.push('', '<details><summary>All scenarios</summary>', '', *sweep_tables, '', '</details>')
      lines.push('', '## Not compared', '', *@flags) unless @flags.empty?
      lines.join("\n")
    end

    def warnings
      base = @baseline[:environment]
      cur = @current[:environment]
      [ruby_warning(base, cur), yjit_warning(base, cur), platform_warning(base, cur), load_warning(base, cur),
       dirty_warning(base, cur), samples_warning].compact
    end

    private

    # Color on a terminal only; Rainbow turns itself off when stdout isn't a TTY, so a redirect gets plain markdown.
    def paint(text, color, count = 1) = count.zero? ? text : Rainbow(text).color(color).to_s

    def describe(env)
      "#{env[:git_commit]}#{' with uncommitted changes' if env[:git_dirty]}, #{ruby_version(env)}, " \
        "YJIT #{env[:yjit] ? 'on' : 'off'}"
    end

    def ruby_warning(base, cur)
      b = ruby_version(base)
      c = ruby_version(cur)
      "Ruby differs: baseline #{b}, current #{c}." if b != c
    end

    def ruby_version(env) = env[:ruby].to_s[/\Aruby (\S+)/, 1] || env[:ruby].to_s

    def yjit_warning(base, cur)
      return if base[:yjit] == cur[:yjit]

      "YJIT differs: baseline #{base[:yjit] ? 'on' : 'off'}, current #{cur[:yjit] ? 'on' : 'off'}."
    end

    def platform_warning(base, cur)
      return if base.values_at(:platform, :cpus) == cur.values_at(:platform, :cpus)

      "Machine differs: baseline #{base[:platform]} with #{base[:cpus]} CPUs, current #{cur[:platform]} with " \
        "#{cur[:cpus]} CPUs."
    end

    def samples_warning
      few = { 'baseline' => @baseline, 'current' => @current }.select { |_, d| d[:knobs][:samples] < MIN_SAMPLES }.keys
      return if few.empty?

      "Fewer than #{MIN_SAMPLES} batches per scenario in the #{few.join(' and ')} run (QUICK=1?); time changes " \
        'there are not a reliable signal. Allocation counts and output digests are.'
    end

    def dirty_warning(base, cur)
      dirty = { 'baseline' => base[:git_dirty], 'current' => cur[:git_dirty] }.select { |_, d| d }.keys
      "Uncommitted changes in the #{dirty.join(' and ')} run; the commit alone doesn't identify the code." if dirty.any?
    end

    # The 1-minute load averages at the start and end of each run, averaged. Flagged when the busier run is at least
    # 1.0 above the other and 1.5x it.
    def load_warning(base, cur)
      b = mean_load(base)
      c = mean_load(cur)
      return unless b && c
      return unless (b - c).abs >= 1.0 && [b, c].max >= 1.5 * [b, c].min

      format('Load differs: baseline %<b>.1f, current %<c>.1f (mean 1-minute load average over each run).', b: b, c: c)
    end

    def mean_load(env)
      loads = [env[:load_average_start], env[:load_average_end]].filter_map { |l| l&.first }
      loads.sum / loads.size unless loads.empty?
    end

    def collect_rows
      base_sweeps = @baseline[:sweeps].to_h { |s| [s[:name], s] }
      rows = @current[:sweeps].flat_map do |sweep|
        base = base_sweeps.delete(sweep[:name])
        next @flags << "- sweep `#{sweep[:name]}` is not in the baseline" unless base
        next @flags << "- sweep `#{sweep[:name]}` has no per-scenario results to compare" if sweep[:results].is_a?(Hash)

        sweep_rows(sweep, base)
      end
      unless base_sweeps.empty?
        @flags << "- sweeps in the baseline but not in this run: #{base_sweeps.keys.map { |n| "`#{n}`" }.join(', ')}"
      end
      rows.grep(Row)
    end

    def sweep_rows(sweep, base)
      base_results = base[:results].to_h { |r| [r[:label], r] }
      rows = sweep[:results].flat_map do |result|
        before = base_results.delete(result[:label])
        next @flags << "- #{sweep[:name]} / #{result[:label]}: not in the baseline" unless before

        result_rows(sweep, result, before)
      end
      base_results.each_key { |label| @flags << "- #{sweep[:name]} / #{label}: in the baseline but not in this run" }
      rows
    end

    def result_rows(sweep, result, before)
      now_engines = result[:engines] || {}
      before_engines = before[:engines] || {}
      (now_engines.keys - before_engines.keys).each do |e|
        @flags << "- #{sweep[:name]} / #{result[:label]}: #{e} is not in the baseline"
      end
      (before_engines.keys - now_engines.keys).each do |e|
        @flags << "- #{sweep[:name]} / #{result[:label]}: #{e} is in the baseline but not in this run"
      end
      (now_engines.keys & before_engines.keys).map do |key|
        Row.new(sweep: sweep[:name], title: sweep[:title], label: result[:label], engine: key.to_s,
                before: before_engines[key], after: now_engines[key])
      end
    end

    def changed_table(changed)
      return ['Nothing beyond noise.'] if changed.empty?

      head = ['scenario', 'ms', 'time', 'CPU', 'alloc/obj', 'alloc', 'output']
      Markdown.table(head, changed.map { |row| [row.where, *cells(row), row.output_changed? ? 'changed' : 'same'] })
    end

    def sweep_tables
      @rows.group_by(&:sweep).flat_map do |sweep, rows|
        multi = rows.any? { |r| r.engine != ENGINE }
        head = [rows.first.title, *(['engine'] if multi), 'ms', 'time', 'CPU', 'alloc/obj', 'alloc']
        body = rows.map { |r| [r.label, *([r.engine] if multi), *cells(r)] }
        ['', "### #{sweep}: #{rows.first.title}", '', *Markdown.table(head, body)]
      end
    end

    def cells(row)
      a = row.before
      b = row.after
      ["#{Markdown.num(a[:median_ms])} -> #{Markdown.num(b[:median_ms])}", timed(row, ''), timed(row, 'cpu_'),
       "#{Markdown.num(a[:allocations_per_object])} -> #{Markdown.num(b[:allocations_per_object])}",
       change(a[:allocations_per_object], b[:allocations_per_object])]
    end

    def timed(row, prefix)
      text = change(row.before[:"#{prefix}median_ms"], row.after[:"#{prefix}median_ms"])
      return text if text == 'n/a' || text == '0%' || row.beyond_noise?(prefix)

      "~ #{text}"
    end

    def change(before, after)
      return 'n/a' unless before&.positive? && after

      pct = (after - before) / before * 100
      text = pct.abs >= 10 ? format('%.0f', pct.abs) : format('%.1f', pct.abs)
      return '0%' if text.to_f.zero?

      "#{pct.negative? ? MINUS : '+'}#{text}%"
    end
  end
end
