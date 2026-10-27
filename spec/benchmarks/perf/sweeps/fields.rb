# frozen_string_literal: true

module PerfBench
  sweep 'field_kinds', 'Field kinds',
        'Baseline as plain objects (attr_reader) with all 20 fields of one kind. Plain objects rather than Hashes, ' \
        'because Symbol#to_proc blocks and extractors call methods on the object.' do
    poros = -> { Fixtures.convert(Fixtures.widgets(BASELINE_SIZE), :poro) }

    scenario 'plain' do
      Setup.new(input: poros, engines: PerfBench.baseline_engines)
    end

    scenario 'renamed (name:)' do
      blueprint = Blueprints.widget(fields: false) { NAMES.each { |n| field n, name: :"out_#{n}" } }
      Setup.new(input: poros, engines: PerfBench.hash_engines(blueprint))
    end

    scenario 'block (1 arg)' do
      blueprint = Blueprints.widget(fields: false) { NAMES.each { |n| field(n) { |obj| obj.public_send(n) } } }
      Setup.new(input: poros, engines: PerfBench.hash_engines(blueprint))
    end

    scenario 'block (2 args)' do
      blueprint = Blueprints.widget(fields: false) do
        NAMES.each { |n| field(n) { |obj, _options| obj.public_send(n) } }
      end
      Setup.new(input: poros, engines: PerfBench.hash_engines(blueprint))
    end

    scenario 'Symbol#to_proc' do
      blueprint = Blueprints.widget(fields: false) { NAMES.each { |n| field(n, &n) } }
      Setup.new(input: poros, engines: PerfBench.hash_engines(blueprint))
    end

    scenario 'custom extractor' do
      blueprint = Blueprints.widget(fields: false) { NAMES.each { |n| field n, extractor: EXTRACTOR } }
      Setup.new(input: poros, engines: PerfBench.hash_engines(blueprint))
    end
  end

  sweep 'conditions', 'Conditions',
        'Baseline with a condition on all 20 fields. 50% rows skip every other field. Global: `config.if`, which ' \
        'every field checks.' do
    hashes = -> { Fixtures.widgets(BASELINE_SIZE) }

    scenario 'none' do
      Setup.new(input: hashes, engines: PerfBench.baseline_engines)
    end

    [0, 50].each do |skip|
      skipped = skip.zero? ? [] : HALF

      scenario "Proc if, #{skip}% skipped" do
        blueprint = Blueprints.widget(fields: false) do
          NAMES.each { |n| field n, if: ->(_name, _obj, _opts) { !skipped.include?(n) } }
        end
        Setup.new(input: hashes, engines: PerfBench.hash_engines(blueprint))
      end

      scenario "Symbol if, #{skip}% skipped" do
        blueprint = Blueprints.widget(fields: false) do
          define_singleton_method(:show?) { |name, _obj, _opts| !skipped.include?(name) }
          NAMES.each { |n| field n, if: :show? }
        end
        Setup.new(input: hashes, engines: PerfBench.hash_engines(blueprint))
      end

      global_if = ->(name, _obj, _opts) { !skipped.include?(name) }
      scenario "global if, #{skip}% skipped", config: ->(c) { c.if = global_if } do
        Setup.new(input: hashes, engines: PerfBench.baseline_engines)
      end
    end

    scenario 'Proc unless, 0% skipped' do
      blueprint = Blueprints.widget(fields: false) do
        NAMES.each { |n| field n, unless: ->(_name, _obj, _opts) { false } }
      end
      Setup.new(input: hashes, engines: PerfBench.hash_engines(blueprint))
    end
  end
end
