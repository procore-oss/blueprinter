# frozen_string_literal: true

require 'digest'
require 'json'
require_relative 'harness'

module PerfBench
  # Runs a scenario: the correctness gate, then interleaved timing, allocation counts, and a GC-pressure run.
  class Runner
    Knobs = Struct.new(:samples, :sample_ms, :budget_s, :gc_ms, :warmup_ms, :seed, keyword_init: true)

    DEFAULTS = { samples: 40, sample_ms: 2, budget_s: 2, gc_ms: 250, warmup_ms: 100 }.freeze
    # QUICK=1: a pass over every scenario in well under a minute, for checking that a change runs
    QUICK = { samples: 3, sample_ms: 1, budget_s: 0.3, gc_ms: 30, warmup_ms: 20 }.freeze

    def self.quick? = ENV['QUICK'] == '1'

    def self.knobs_from_env
      defaults = quick? ? QUICK : DEFAULTS
      Knobs.new(
        samples: Integer(ENV.fetch('SAMPLES', defaults[:samples].to_s)),
        sample_ms: Float(ENV.fetch('SAMPLE_MS', defaults[:sample_ms].to_s)),
        budget_s: Float(ENV.fetch('BUDGET_S', defaults[:budget_s].to_s)),
        gc_ms: Float(ENV.fetch('GC_MS', defaults[:gc_ms].to_s)),
        warmup_ms: Float(ENV.fetch('WARMUP_MS', defaults[:warmup_ms].to_s)),
        seed: Integer(ENV.fetch('SEED', Random.new_seed.to_s))
      )
    end

    # The scenario's input builder, memoized unless the scenario asks for fresh input per job.
    def self.input_for(setup, scenario)
      return setup.input if scenario.fresh_input

      value = setup.input.call
      -> { value }
    end

    attr_reader :knobs

    def initialize(knobs, log: $stderr)
      @knobs = knobs
      @log = log
      @rng = Random.new(knobs.seed)
    end

    # @return [Hash] JSON-ready result for one scenario
    def run(scenario)
      Blueprinter.reset_configuration!
      scenario.config&.call(Blueprinter.configuration)
      setup = scenario.build.call
      engines = setup.engines.to_h { |eng| [eng.name, eng] }
      input = Runner.input_for(setup, scenario)

      gate = Gate.new(engines, input).check
      result = { sweep: scenario.sweep.name, label: scenario.label, note: scenario.note,
                 rendered_objects: gate.rendered_objects, excluded: gate.excluded, engines: {} }
      timed = engines.reject { |name, _| gate.excluded.key?(name) }
      result[:engines] = measure(timed, input, gate).to_h unless timed.empty?
      result
    ensure
      Blueprinter.reset_configuration!
    end

    private

    def measure(engines, input, gate)
      calibration = engines.transform_values { |eng| warm(eng, input) }
      samples = engines.to_h { |name, _| [name, { wall: [], cpu: [] }] }
      rounds = calibration.values.map { |c| c[:samples] }.max

      rounds.times do |round|
        engines.keys.shuffle(random: @rng).each do |name|
          next if round >= calibration[name][:samples]

          sample(engines[name], input, calibration[name][:reps], samples[name])
        end
      end

      engines.to_h do |name, eng|
        gc = gc_pressure(eng, input, calibration[name])
        summary = summarize(samples[name], calibration[name], allocations(eng, input), gc, gate.rendered_objects)
        [name, summary.merge(output_digest: gate.digests[name])]
      end
    end

    # Runs the engine until both a render count and a time floor are reached, then picks the batch size (reps) and
    # sample count from the steady-state render time.
    def warm(eng, input)
      times = []
      started = now
      loop do
        job = eng.job(input.call)
        t = now
        job.call
        times << (now - t)
        elapsed = now - started
        break if (times.size >= 30 && elapsed * 1000 >= knobs.warmup_ms) || (times.size >= 2 && elapsed > 1.0)
      end
      per_render = times.last(5).min
      reps = (knobs.sample_ms / 1000.0 / per_render).ceil.clamp(1, 2_000)
      affordable = (knobs.budget_s / (per_render * reps)).floor
      { per_render:, reps:, samples: affordable.clamp([knobs.samples, 5].min, knobs.samples) }
    end

    def sample(eng, input, reps, into)
      jobs = Array.new(reps) { eng.job(input.call) }
      c = cpu_now
      t = now
      jobs.each(&:call)
      wall = now - t
      into[:wall] << (wall / reps)
      into[:cpu] << ((cpu_now - c) / reps) if c
    end

    # Objects allocated by one render, with GC disabled so nothing is collected mid-count. The minimum of three runs.
    def allocations(eng, input)
      Array.new(3) do
        job = eng.job(input.call)
        GC.start
        GC.disable
        before = GC.stat(:total_allocated_objects)
        job.call
        GC.stat(:total_allocated_objects) - before
      ensure
        GC.enable
      end.min
    end

    # GC work over a longer run. Jobs are built in batches between measured stretches, so input construction is
    # outside the counted GC time but its garbage still adds to the heap the renders run against.
    def gc_pressure(eng, input, calibration)
      target = (knobs.gc_ms / 1000.0 / calibration[:per_render]).ceil.clamp(3, 200_000)
      batch = calibration[:reps]
      totals = Hash.new(0.0)
      GC.start
      done = 0
      while done < target
        jobs = Array.new([batch, target - done].min) { eng.job(input.call) }
        before = GC.stat
        t = now
        jobs.each(&:call)
        totals[:wall] += now - t
        after = GC.stat
        %i[count minor_gc_count major_gc_count].each { |k| totals[k] += after[k] - before[k] }
        totals[:time_ms] += after[:time] - before[:time] if after.key?(:time)
        done += jobs.size
      end
      { renders: done, gc_ms_per_render: GC.stat.key?(:time) ? totals[:time_ms] / done : nil,
        gc_share: GC.stat.key?(:time) ? totals[:time_ms] / (totals[:wall] * 1000) : nil,
        gc_runs_per_1k_renders: totals[:count] * 1000 / done, major_gc_runs: totals[:major_gc_count].to_i }
    end

    # The interquartile range of the batch means is the run's own noise estimate: a change between two runs smaller
    # than either run's IQR (relative to its median) is within what one run shows on its own.
    def summarize(samples, calibration, allocs, gc, rendered_objects)
      wall = samples[:wall].sort
      cpu = samples[:cpu].sort
      {
        samples: wall.size, reps: calibration[:reps],
        median_ms: ms(percentile(wall, 50)), p25_ms: ms(percentile(wall, 25)), p75_ms: ms(percentile(wall, 75)),
        p95_ms: ms(percentile(wall, 95)), p99_ms: ms(percentile(wall, 99)),
        cpu_median_ms: cpu.empty? ? nil : ms(percentile(cpu, 50)),
        cpu_p25_ms: cpu.empty? ? nil : ms(percentile(cpu, 25)), cpu_p75_ms: cpu.empty? ? nil : ms(percentile(cpu, 75)),
        allocations: allocs, allocations_per_object: rendered_objects.positive? ? allocs.fdiv(rendered_objects) : nil,
        gc:
      }
    end

    def percentile(sorted, pct)
      sorted[((pct / 100.0) * sorted.size).ceil.clamp(1, sorted.size) - 1]
    end

    def ms(seconds) = seconds && (seconds * 1000.0)

    def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    def cpu_now
      Process.clock_gettime(Process::CLOCK_THREAD_CPUTIME_ID)
    rescue Errno::EINVAL, NameError
      nil
    end
  end

  # Renders the scenario once with every engine before timing. An engine that raises, or that issues SQL while
  # rendering (associations not preloaded), is excluded with the reason. The output's digest is kept so a later run
  # can tell whether a change altered what gets rendered, not only how fast.
  class Gate
    Outcome = Struct.new(:rendered_objects, :excluded, :digests, keyword_init: true)

    def initialize(engines, input)
      @engines = engines
      @input = input
    end

    def check
      excluded = {}
      digests = {}
      rendered = nil
      @engines.each do |name, eng|
        out = nil
        job = eng.job(@input.call)
        queries = Records.count_queries { out = job.call }
        if queries.positive?
          excluded[name] = "render issued #{queries} SQL queries (associations not preloaded)"
        else
          parsed = parse(out)
          rendered ||= count_hashes(parsed)
          digests[name] = Digest::SHA256.hexdigest(canonical(parsed).inspect)[0, 16]
        end
      rescue StandardError => e
        excluded[name] = "raised #{e.class}: #{e.message.lines.first&.strip}"
      end
      Outcome.new(rendered_objects: rendered || 0, excluded:, digests:)
    end

    private

    def parse(out) = out.is_a?(String) ? JSON.parse(out) : out

    # Hashes become key-sorted pair lists, so the digest doesn't depend on field order. Keys keep their type.
    def canonical(value)
      case value
      when Hash then value.map { |k, v| [k, canonical(v)] }.sort_by { |(k, _)| k.to_s }
      when Array then value.map { |v| canonical(v) }
      else value
      end
    end

    def count_hashes(value)
      case value
      when Hash then 1 + value.each_value.sum { |v| count_hashes(v) }
      when Array then value.sum { |v| count_hashes(v) }
      else 0
      end
    end
  end
end
