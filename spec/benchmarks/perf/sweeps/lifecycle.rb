# frozen_string_literal: true

module PerfBench
  sweep 'lifecycle', 'Lifecycle',
        'One widget (20 fields, company, 3 parts). First-render rows define fresh classes before every timed render, ' \
        'so they include compiling the views of every blueprint in the tree.' do
    single = -> { Fixtures.widgets(1).first }

    scenario 'warm' do
      Setup.new(input: single, engines: PerfBench.baseline_engines)
    end

    scenario 'first render (definition untimed)' do
      Setup.new(input: single, engines: [
        engine(prepare: lambda { |input|
          bp = Blueprints.widget
          -> { bp.render_as_hash(input) }
        })
      ])
    end

    scenario 'definition + first render' do
      Setup.new(input: single, engines: [
        engine(prepare: ->(input) { -> { Blueprints.widget.render_as_hash(input) } })
      ])
    end

    scenario 'first render of a named view', note: 'The blueprint has 3 views; the first render compiles every view.' do
      views = proc { %i[a b c].each_with_index { |v, i| view(v) { fields(*EXTRA.drop(i * 3).first(3)) } } }
      Setup.new(input: -> { Fixtures.widgets(1, width: 30).first }, engines: [
        engine(prepare: lambda { |input|
          bp = Blueprints.widget(&views)
          -> { bp.render_as_hash(input, view: :b) }
        })
      ])
    end

    scenario 'boot: 50 blueprints, first render each', note: '50 distinct widget blueprints (each with its own company ' \
                                                             'and part blueprints) defined untimed, then each ' \
                                                             'rendered once.' do
      Setup.new(input: single, engines: [
        engine(prepare: lambda { |input|
          bps = Array.new(50) { Blueprints.widget }
          -> { bps.map { |bp| bp.render_as_hash(input) } }
        })
      ])
    end
  end

  # Throughput of N threads rendering one blueprint, and first renders racing on freshly defined classes.
  module Concurrency
    THREADS = [1, 2, 4, 8].freeze
    RACES = 20
    CHECK_EVERY = 16

    module_function

    def run(knobs)
      input = Fixtures.widgets(BASELINE_SIZE)
      build = -> { Blueprints.widget.method(:render_as_hash) }
      expected = build.call.call(input)

      duration = (knobs.budget_s / 3).clamp(0.05, 1.0)
      rows = THREADS.map do |threads|
        render = build.call
        50.times { render.call(input) }
        stats = steady(render, input, expected, threads, duration).merge(races(build, input, expected, threads))
        [threads, stats[:rate].round, "#{stats[:races_ok]}/#{RACES}", stats[:bad] + stats[:race_bad]]
      end
      { columns: ['threads', 'renders/s', 'races ok', 'bad outputs'],
        rows:,
        notes: ["Steady state: #{(duration * 1000).round} ms per row; every #{CHECK_EVERY}th output is compared " \
                'with the expected Hash.',
                "Races: #{RACES} trials per row, each defining fresh classes and releasing all threads into their " \
                'first render at once (the ViewCollection mutex); every output is compared.',
                'Threads share the GVL, so throughput measures contention overhead, not parallel speedup.'] }
    end

    def steady(render, input, expected, threads, duration)
      bad = 0
      counts = Array.new(threads, 0)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + duration
      Array.new(threads) do |t|
        Thread.new do
          while Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
            out = render.call(input)
            bad += 1 if (counts[t] % CHECK_EVERY).zero? && out != expected
            counts[t] += 1
          end
        end
      end.each(&:join)
      { rate: counts.sum / duration, bad: }
    end

    def races(build, input, expected, threads)
      ok = 0
      bad = 0
      RACES.times do
        render = build.call
        gate = Queue.new
        workers = Array.new(threads) do
          Thread.new do
            gate.pop
            render.call(input)
          rescue StandardError => e
            e
          end
        end
        threads.times { gate << true }
        outputs = workers.map(&:value)
        failures = outputs.count { |out| out != expected }
        bad += failures
        ok += 1 if failures.zero?
      end
      { races_ok: ok, race_bad: bad }
    end
  end

  sweep 'concurrency', 'Concurrency', 'Baseline (100 widgets) rendered by N threads.' do
    run_with { |runner| Concurrency.run(runner.knobs) }
  end
end
