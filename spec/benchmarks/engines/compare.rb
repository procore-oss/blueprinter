# frozen_string_literal: true

require 'json'

module EngineBench
  # Compares a finished run with an earlier results file (BASELINE=path.json): the change in median time and in
  # allocations per rendered object for every scenario and engine present in both, plus warnings when the two runs
  # weren't made under comparable conditions.
  class Compare
    MINUS = '−'

    def initialize(baseline_path, current_path)
      @baseline = JSON.parse(File.read(baseline_path))
      @current = JSON.parse(File.read(current_path))
      @baseline_path = baseline_path
      @current_path = current_path
    end

    def markdown
      lines = ['# Comparison with baseline', '',
               "- Baseline: `#{@baseline_path}`", "- Current: `#{@current_path}`",
               '- Change is (current - baseline) / baseline for the median time and for allocations per rendered ' \
               'object; negative is faster or fewer allocations.']
      warnings.each { |w| lines << "- **Warning:** #{w}" }
      lines << ''
      flags = []
      lines.concat(sweep_tables(flags))
      lines.concat(['', '## Not compared', '', *flags]) unless flags.empty?
      lines.join("\n")
    end

    def warnings
      base = @baseline['environment']
      cur = @current['environment']
      [ruby_warning(base, cur), yjit_warning(base, cur), platform_warning(base, cur), load_warning(base, cur)].compact
    end

    private

    def ruby_warning(base, cur)
      b = ruby_version(base)
      c = ruby_version(cur)
      "Ruby differs: baseline #{b}, current #{c}." if b != c
    end

    def ruby_version(env) = env['ruby'].to_s[/\Aruby (\S+)/, 1] || env['ruby'].to_s

    def yjit_warning(base, cur)
      return if base['yjit'] == cur['yjit']

      "YJIT differs: baseline #{base['yjit'] ? 'on' : 'off'}, current #{cur['yjit'] ? 'on' : 'off'}."
    end

    def platform_warning(base, cur)
      return if base.values_at('platform', 'cpus') == cur.values_at('platform', 'cpus')

      "Machine differs: baseline #{base['platform']} with #{base['cpus']} CPUs, current #{cur['platform']} with " \
        "#{cur['cpus']} CPUs."
    end

    # The 1-minute load averages at the start and end of each run, averaged. Flagged when the busier run is at least
    # 1.0 above the other and 1.5x it.
    def load_warning(base, cur)
      b = mean_load(base)
      c = mean_load(cur)
      return unless b && c
      return unless (b - c).abs >= 1.0 && [b, c].max >= 1.5 * [b, c].min

      format('Load differs: baseline %.1f, current %.1f (mean 1-minute load average over each run).', b, c)
    end

    def mean_load(env)
      loads = [env['load_average_start'], env['load_average_end']].filter_map { |l| l&.first }
      loads.sum / loads.size unless loads.empty?
    end

    def sweep_tables(flags)
      base_sweeps = @baseline['sweeps'].to_h { |s| [s['name'], s] }
      out = []
      @current['sweeps'].each do |sweep|
        base = base_sweeps.delete(sweep['name'])
        next flags << "- sweep `#{sweep['name']}` is not in the baseline" unless base
        next flags << "- sweep `#{sweep['name']}` has no per-scenario results to compare" if sweep['results'].is_a?(Hash)

        out.concat(sweep_table(sweep, base, flags))
      end
      unless base_sweeps.empty?
        flags << "- sweeps in the baseline but not in this run: #{base_sweeps.keys.map { |n| "`#{n}`" }.join(', ')}"
      end
      out
    end

    def sweep_table(sweep, base, flags)
      base_results = base['results'].to_h { |r| [r['label'], r] }
      rows = []
      sweep['results'].each do |result|
        before = base_results.delete(result['label'])
        next flags << "- #{sweep['name']} / #{result['label']}: not in the baseline" unless before

        rows.concat(result_rows(sweep['name'], result, before, flags))
      end
      base_results.each_key { |label| flags << "- #{sweep['name']} / #{label}: in the baseline but not in this run" }
      return [] if rows.empty?

      ['', "## #{sweep['name']}: #{sweep['title']}", '', *table(sweep['title'], rows)]
    end

    def result_rows(sweep_name, result, before, flags)
      now_engines = result['engines'] || {}
      before_engines = before['engines'] || {}
      (now_engines.keys - before_engines.keys).each do |e|
        flags << "- #{sweep_name} / #{result['label']}: #{e} is not in the baseline"
      end
      (before_engines.keys - now_engines.keys).each do |e|
        flags << "- #{sweep_name} / #{result['label']}: #{e} is in the baseline but not in this run"
      end
      (now_engines.keys & before_engines.keys).map do |engine|
        a = before_engines[engine]
        b = now_engines[engine]
        [result['label'], engine, "#{ms(a['median_ms'])} -> #{ms(b['median_ms'])}", change(a['median_ms'], b['median_ms']),
         "#{ms(a['allocations_per_object'])} -> #{ms(b['allocations_per_object'])}",
         change(a['allocations_per_object'], b['allocations_per_object'])]
      end
    end

    def table(axis, rows)
      head = [axis, 'engine', 'median ms', 'time', 'alloc/obj', 'alloc']
      ["| #{head.join(' | ')} |", "|#{head.map { ' --- |' }.join}",
       *rows.map { |r| "| #{r.map { |c| c.to_s.gsub('|', '\\|') }.join(' | ')} |" }]
    end

    def change(before, after)
      return 'n/a' unless before&.positive? && after

      pct = (after - before) / before * 100
      text = pct.abs >= 10 ? format('%.0f', pct.abs) : format('%.1f', pct.abs)
      return '0%' if text.to_f.zero?

      "#{pct.negative? ? MINUS : '+'}#{text}%"
    end

    def ms(value)
      return 'n/a' if value.nil?

      value >= 100 ? format('%.0f', value) : format('%.4g', value)
    end
  end
end
