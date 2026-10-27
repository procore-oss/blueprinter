# frozen_string_literal: true

require 'json'
require_relative 'harness'

module EngineBench
  # Runs a scenario: the correctness gate, then interleaved timing, allocation counts, and a GC-pressure run.
  class Runner
    Knobs = Struct.new(:samples, :sample_ms, :budget_s, :gc_ms, :warmup_ms, :seed, keyword_init: true)

    def self.knobs_from_env
      Knobs.new(
        samples: Integer(ENV.fetch('SAMPLES', '40')),
        sample_ms: Float(ENV.fetch('SAMPLE_MS', '2')),
        budget_s: Float(ENV.fetch('BUDGET_S', '2')),
        gc_ms: Float(ENV.fetch('GC_MS', '250')),
        warmup_ms: Float(ENV.fetch('WARMUP_MS', '100')),
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
      scenario.v1_config&.call(Blueprinter.configuration)
      setup = scenario.build.call
      engines = setup.engines.to_h { |eng| [eng.name, eng] }
      input = Runner.input_for(setup, scenario)

      gate = Gate.new(engines, input).check
      result = { sweep: scenario.sweep.name, label: scenario.label, note: scenario.note,
                 rendered_objects: gate.rendered_objects, excluded: gate.excluded, engines: {} }
      timed = engines.reject { |name, _| gate.excluded.key?(name) }
      result[:engines] = measure(timed, input, gate.rendered_objects) unless timed.empty?
      result
    ensure
      Blueprinter.reset_configuration!
    end

    private

    def measure(engines, input, rendered_objects)
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
        [name, summarize(samples[name], calibration[name], allocations(eng, input), gc, rendered_objects)]
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

    def summarize(samples, calibration, allocs, gc, rendered_objects)
      wall = samples[:wall].sort
      cpu = samples[:cpu].sort
      {
        samples: wall.size, reps: calibration[:reps],
        median_ms: ms(percentile(wall, 50)), p95_ms: ms(percentile(wall, 95)), p99_ms: ms(percentile(wall, 99)),
        cpu_median_ms: cpu.empty? ? nil : ms(percentile(cpu, 50)),
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

  # Renders the scenario once with every engine and requires identical output. Hash keys are compared
  # order-insensitively, since V1 sorts fields by name by default and V2 keeps definition order.
  class Gate
    Outcome = Struct.new(:rendered_objects, :excluded, keyword_init: true)

    def initialize(engines, input)
      @engines = engines
      @input = input
    end

    def check
      outputs = {}
      excluded = {}
      @engines.each do |name, eng|
        out = nil
        job = eng.job(@input.call)
        queries = Records.count_queries { out = job.call }
        if queries.positive?
          excluded[name] = "render issued #{queries} SQL queries (associations not preloaded)"
        else
          outputs[name] = parse(out)
        end
      rescue StandardError => e
        excluded[name] = "raised #{e.class}: #{e.message.lines.first&.strip}"
      end

      reference_name = outputs.key?('V1') ? 'V1' : outputs.keys.first
      reference = reference_name && canonical(outputs[reference_name])
      outputs.each do |name, out|
        next if name == reference_name

        diff = Gate.diff(reference, canonical(out))
        excluded[name] = "output differs from #{reference_name} at #{diff}" if diff
      end
      Outcome.new(rendered_objects: reference_name ? count_hashes(outputs[reference_name]) : 0, excluded:)
    end

    def self.diff(expected, actual, path = '$')
      return nil if expected == actual
      return "#{path}: #{expected.inspect[0, 60]} vs #{actual.inspect[0, 60]}" unless expected.instance_of?(actual.class)

      if expected.is_a?(Array)
        return "#{path}: #{expected.size} vs #{actual.size} entries" unless expected.size == actual.size

        expected.each_with_index do |e, i|
          a = actual[i]
          d =
            if pair?(e) && pair?(a)
              e[1] == a[1] ? diff(e[2], a[2], "#{path}.#{e[1]}") : "#{path}: key #{e[1].inspect} vs #{a[1].inspect}"
            else
              diff(e, a, "#{path}[#{i}]")
            end
          return d if d
        end
      end
      "#{path}: #{expected.inspect[0, 60]} vs #{actual.inspect[0, 60]}"
    end

    def self.pair?(value) = value.is_a?(Array) && value.first == :__pair

    private

    def parse(out) = out.is_a?(String) ? JSON.parse(out) : out

    # Hashes become key-sorted pair lists; pair lists keep key types, so Symbol vs String keys still differ.
    def canonical(value)
      case value
      when Hash then value.map { |k, v| [:__pair, k, canonical(v)] }.sort_by { |(_, k, _)| k.to_s }
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
