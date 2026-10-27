# frozen_string_literal: true

module EngineBench
  sweep 'lifecycle', 'Lifecycle',
        'One widget (20 fields, company, 3 parts). First-render rows define fresh classes before every timed render, ' \
        'so they include V1 compilation and V2 evaluation of every blueprint in the tree.' do
    single = -> { Fixtures.widgets(1).first }

    scenario 'warm' do
      Setup.new(input: single, engines: EngineBench.baseline_engines)
    end

    scenario 'first render (definition untimed)' do
      Setup.new(input: single, engines: [
        engine('V1', prepare: lambda { |input|
          bp = Blueprints::V1.widget
          -> { bp.render_as_hash(input) }
        }),
        engine('V2', prepare: lambda { |input|
          bp = Blueprints::V2.widget
          -> { bp.render(input).to_hash }
        })
      ])
    end

    scenario 'definition + first render' do
      Setup.new(input: single, engines: [
        engine('V1', prepare: ->(input) { -> { Blueprints::V1.widget.render_as_hash(input) } }),
        engine('V2', prepare: ->(input) { -> { Blueprints::V2.widget.render(input).to_hash } })
      ])
    end

    scenario 'first render of a named view', note: 'The blueprint has 3 views; V2 evaluates the parent and the view, ' \
                                                   'V1 compiles every view on first render.' do
      v1_views = proc { %i[a b c].each_with_index { |v, i| view(v) { fields(*EXTRA.drop(i * 3).first(3)) } } }
      v2_views = proc { %i[a b c].each_with_index { |v, i| view(v) { fields(*EXTRA.drop(i * 3).first(3)) } } }
      Setup.new(input: -> { Fixtures.widgets(1, width: 30).first }, engines: [
        engine('V1', prepare: lambda { |input|
          bp = Blueprints::V1.widget(&v1_views)
          -> { bp.render_as_hash(input, view: :b) }
        }),
        engine('V2', prepare: lambda { |input|
          bp = Blueprints::V2.widget(&v2_views)
          -> { bp[:b].render(input).to_hash }
        })
      ])
    end

    scenario 'boot: 50 blueprints, first render each', note: '50 distinct widget blueprints (each with its own company ' \
                                                             'and part blueprints) defined untimed, then each ' \
                                                             'rendered once.' do
      Setup.new(input: single, engines: [
        engine('V1', prepare: lambda { |input|
          bps = Array.new(50) { Blueprints::V1.widget }
          -> { bps.map { |bp| bp.render_as_hash(input) } }
        }),
        engine('V2', prepare: lambda { |input|
          bps = Array.new(50) { Blueprints::V2.widget }
          -> { bps.map { |bp| bp.render(input).to_hash } }
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
      builders = { 'V1' => -> { Blueprints::V1.widget.method(:render_as_hash) } }
      if EngineBench.v2?
        builders['V2'] = lambda {
          bp = Blueprints::V2.widget
          ->(obj) { bp.render(obj).to_hash }
        }
      end
      expected = builders['V1'].call.call(input)
      raise 'V1 and V2 output differ' if builders.key?('V2') && builders['V2'].call.call(input) != expected

      duration = (knobs.budget_s / 3).clamp(0.05, 1.0)
      rows = THREADS.map do |threads|
        stats = builders.transform_values do |build|
          render = build.call
          50.times { render.call(input) }
          steady(render, input, expected, threads, duration).merge(races(build, input, expected, threads))
        end
        ratio = stats.key?('V2') ? [format('%.2fx', stats['V2'][:rate] / stats['V1'][:rate])] : []
        [threads, *stats.values.map { |s| s[:rate].round }, *ratio,
         *stats.values.map { |s| "#{s[:races_ok]}/#{RACES}" }, stats.values.sum { |s| s[:bad] + s[:race_bad] }]
      end
      names = builders.keys
      { columns: ['threads', *names.map { |n| "#{n} renders/s" }, *(['V2/V1 throughput'] if names.include?('V2')),
                  *names.map { |n| "#{n} races ok" }, 'bad outputs'],
        rows:,
        notes: ["Steady state: #{(duration * 1000).round} ms per engine per row; every #{CHECK_EVERY}th output " \
                'is compared with the expected Hash.',
                "Races: #{RACES} trials per row, each defining fresh classes and releasing all threads into their " \
                'first render at once (V1 ViewCollection mutex, V2 eval_mutex where V2 exists); every output is compared.',
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
