# frozen_string_literal: true

# Measures rendering across one-factor-at-a-time sweeps and realistic profiles, and prints the change against an
# earlier run.
#
#   bundle exec rake perf
#   QUICK=1 bundle exec rake perf                       # every scenario, tiny samples, under a minute
#   SWEEPS=input_kind,size SIZES=1,100 bundle exec rake perf
#   RUBYOPT=--yjit bundle exec rake perf
#   BASELINE=latest bundle exec rake perf               # compare with the newest earlier run (same YJIT mode)
#   BASELINE=a.json CURRENT=b.json bundle exec rake perf:compare
#
# Knobs: SWEEPS (comma-separated names, default all), SAMPLES (max batches per scenario, default 40), SIZES (the size
# sweep's values, `object` for a single object), SAMPLE_MS, BUDGET_S, GC_MS, WARMUP_MS, SEED, PROFILE=0 to skip
# allocation-site tracing, LIST=1 to list sweeps, OUT_DIR (default benchmarks/results), BASELINE (a results JSON
# file, or `latest`, to print the change against). QUICK=1 sets small values for all of them.

require 'blueprinter'
require 'blueprinter/base' # `Blueprinter::Extractor` is only loaded along with Base
require 'io/console'
require 'oj'
require 'rainbow'
require 'ruby-progressbar'

# Optional gems. Scenarios that need one are skipped, with the reason listed in the report, when it isn't installed.
multi_json = begin
  require 'multi_json'
  true
rescue LoadError
  false
end

require_relative 'harness'
PerfBench.provide(:multi_json, multi_json)
require_relative 'fixtures'
require_relative 'records'
require_relative 'blueprints'
require_relative 'runner'
require_relative 'report'
require_relative 'profile'
require_relative 'compare'
Dir[File.join(__dir__, 'sweeps', '*.rb')].each { |f| require f }

module PerfBench
  ORDER = %w[input_kind size width depth fanout association_kind repeated_children sparsity defaults value_types
             field_kinds conditions views transform extensions render_options output lifecycle concurrency breakdown
             profiles].freeze

  PROFILED = [
    ['input_kind', 'Hash (Symbol keys)'],
    %w[input_kind ActiveRecord],
    ['field_kinds', 'block (1 arg)'],
    ['value_types', 'Time, formatted (global)'],
    ['profiles', 'AR orders: 100 orders to a Hash, depth 4'],
    ['profiles', 'Hash export: 5,000 rows, 12 fields, no associations']
  ].freeze

  class << self
    def selected_sweeps
      names = ENV.fetch('SWEEPS', '').split(',').map(&:strip).reject(&:empty?)
      names = (ORDER & sweeps.keys) + (sweeps.keys - ORDER) if names.empty?
      unknown = names - sweeps.keys
      abort "Unknown sweeps: #{unknown.join(', ')}. Known: #{sweeps.keys.join(', ')}" unless unknown.empty?
      names.map { |n| sweeps.fetch(n) }
    end

    def main(args)
      return list if ENV['LIST']
      return compare_only if args.first == 'compare'

      baseline = resolve_baseline(ENV.fetch('BASELINE', nil))
      MultiJson.use(:oj) if feature?(:multi_json)
      runner = Runner.new(Runner.knobs_from_env)
      report = Report.new(runner.knobs)
      progress = Progress.new(selected_sweeps.sum { |s| s.custom ? 1 : s.scenarios.size } + profiled_count)
      selected_sweeps.each do |sweep|
        results =
          if sweep.custom
            progress.step("#{sweep.name} (custom)") { sweep.custom.call(runner) }
          else
            sweep.scenarios.map { |s| progress.step("#{sweep.name} / #{s.label}") { run_scenario(runner, s) } }
          end
        report.add_sweep(sweep, results)
      end
      profile(report, progress) unless ENV['PROFILE'] == '0'
      progress.finish
      json, md = report.finish!.map { |path| relative(path) }
      puts Rainbow("Report  #{md}").bright, Rainbow("JSON    #{json}").bright, ''
      puts report.summary
      if baseline
        puts '', Compare.new(baseline, json).markdown
      else
        puts '', Rainbow("Compare a later run with this one: BASELINE=#{json} bundle exec rake perf").faint
      end
    end

    def relative(path)
      root = "#{Dir.pwd}/"
      path.start_with?(root) ? path.delete_prefix(root) : path
    end

    def list
      sweeps.each_value { |s| puts "#{s.name.ljust(20)} #{s.title} (#{s.scenarios.size} scenarios)" }
    end

    def compare_only
      baseline = resolve_baseline(ENV.fetch('BASELINE', nil)) or abort 'BASELINE=<results json> is required'
      current = ENV.fetch('CURRENT') do
        Report.latest(except: File.expand_path(baseline)) or abort 'no results file to compare'
      end
      abort "CURRENT not found: #{current}" unless File.file?(current)
      puts Compare.new(relative(baseline), relative(current)).markdown
    end

    # @return [String | nil] the path BASELINE names, with `latest` resolved to the newest results file
    def resolve_baseline(value)
      return nil if value.nil? || value.empty?
      return File.file?(value) ? value : abort("BASELINE not found: #{value}") unless value == 'latest'

      latest = Report.latest or abort("BASELINE=latest, but no earlier #{Report.mode} results under #{Report.out_dir}")
      relative(latest)
    end

    def run_scenario(runner, scenario)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = runner.run(scenario)
      result[:seconds] = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(2)
      result
    end

    def profiled_count = ENV['PROFILE'] == '0' ? 0 : PROFILED.size

    def profile(report, progress)
      PROFILED.each do |sweep_name, label|
        scenario = sweeps.fetch(sweep_name).scenarios.find { |s| s.label == label } or raise "no scenario #{label}"
        progress.step("profile #{sweep_name} / #{label}") do
          report.add_profile(profile_scenario(scenario, "#{sweep_name} / #{label}"))
        end
      end
    end

    def profile_scenario(scenario, name)
      Blueprinter.reset_configuration!
      scenario.config&.call(Blueprinter.configuration)
      setup = scenario.build.call
      input = Runner.input_for(setup, scenario)
      engines = setup.engines.to_h { |e| [e.name, e] }
      gate = Gate.new(engines, input).check
      engines = engines.except(*gate.excluded.keys)
      { scenario: name, description: 'Top allocation sites for one warm render.',
        engines: engines.transform_values { |eng| Profile.allocation_sites(eng, input, gate.rendered_objects) } }
    ensure
      Blueprinter.reset_configuration!
    end
  end

  # A progress bar on stderr naming the scenario being measured. When stderr is not a terminal (CI, `2> log`) it
  # prints one line per scenario instead.
  class Progress
    TITLE_WIDTH = 44

    def initialize(total, out: $stderr)
      @total = total
      @out = out
      @done = 0
      @started = now
      return unless out.tty?

      @bar = ProgressBar.create(total: total, output: out, title: ''.ljust(TITLE_WIDTH), length: width(out),
                                format: '%c/%C |%B| %p%% %e  %t', remainder_mark: ' ', progress_mark: '=',
                                projector: { type: 'smoothing', strength: 0.4 })
    end

    def step(name)
      @bar&.title = title(name)
      t = now
      result = yield
      @done += 1
      if @bar
        @bar.increment
      else
        @out.puts format('[%<done>s/%<total>d] %<name>s  %<took>.1fs', done: @done.to_s.rjust(@total.to_s.size),
                                                                       total: @total, name: name, took: now - t)
      end
      result
    end

    def finish
      @bar&.title = 'done'.ljust(TITLE_WIDTH)
      @bar&.finish
      @out.puts format('%<n>d scenarios in %<clock>s', n: @done, clock: clock(now - @started))
    end

    private

    def width(out)
      cols = out.winsize[1]
      cols.positive? ? [cols, 120].min : 100
    rescue Errno::ENOTTY, Errno::EBADF
      100
    end

    def title(name) = (name.size > TITLE_WIDTH ? "#{name[0, TITLE_WIDTH - 1]}…" : name).ljust(TITLE_WIDTH)

    def clock(seconds) = format('%<m>d:%<s>02d', m: seconds / 60, s: seconds % 60)

    def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end

PerfBench.main(ARGV)
