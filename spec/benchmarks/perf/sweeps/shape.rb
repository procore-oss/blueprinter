# frozen_string_literal: true

module PerfBench
  sweep 'input_kind', 'Input object kind',
        'Baseline shape as each input kind. ActiveRecord: in-memory SQLite, associations preloaded, records loaded ' \
        'fresh for every render (outside the timed region) so attribute casting is paid by each render.' do
    { 'Hash (Symbol keys)' => :hash, 'plain object (attr_reader)' => :poro, 'Struct' => :struct }.each do |label, kind|
      scenario label do
        input = -> { Fixtures.convert(Fixtures.widgets(BASELINE_SIZE), kind) }
        Setup.new(input:, engines: PerfBench.baseline_engines)
      end
    end

    scenario 'ActiveRecord', fresh_input: true do
      Setup.new(input: -> { Records.widgets(BASELINE_SIZE) }, engines: PerfBench.baseline_engines)
    end

    scenario 'ActiveRecord, single object', fresh_input: true do
      Setup.new(input: -> { Records.widgets(1).first }, engines: PerfBench.baseline_engines)
    end

    scenario 'Struct, single object' do
      Setup.new(input: -> { Fixtures.convert(Fixtures.widgets(1), :struct).first }, engines: PerfBench.baseline_engines)
    end
  end

  sweep 'size', 'Collection size', 'Baseline widgets; `object` is a single widget rather than a one-element Array.' do
    PerfBench.size_axis([:object, 1, 10, 100, 1_000, 10_000]).each do |size|
      label = size == :object ? 'object' : size.to_s.reverse.scan(/\d{1,3}/).join(',').reverse
      scenario label do
        count = size == :object ? 1 : size
        Setup.new(input: -> { Fixtures.sized(Fixtures.widgets(count), size) }, engines: PerfBench.baseline_engines)
      end
    end
  end

  sweep 'width', 'Fields per object', 'Baseline with 5, 20, or 50 plain fields on each widget.' do
    [5, 20, 50].each do |width|
      scenario width do
        Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE, width:) }, engines: PerfBench.baseline_engines(width:))
      end
    end
  end

  sweep 'breakdown', 'Where the time goes (baseline, built up)',
        'Each row adds one part of the baseline to the previous row; the deltas between rows show what each part costs.' do
    hashes = -> { Fixtures.widgets(BASELINE_SIZE) }

    scenario 'id only' do
      Setup.new(input: hashes, engines: PerfBench.hash_engines(Blueprints.widget(width: 0, company: nil, part: nil)))
    end

    scenario '+ 20 plain fields' do
      Setup.new(input: hashes, engines: PerfBench.hash_engines(Blueprints.widget(company: nil, part: nil)))
    end

    scenario '+ object association' do
      Setup.new(input: hashes, engines: PerfBench.hash_engines(Blueprints.widget(part: nil)))
    end

    scenario '+ collection association (baseline)' do
      Setup.new(input: hashes, engines: PerfBench.baseline_engines)
    end

    scenario '+ JSON (stdlib)' do
      Setup.new(input: hashes, engines: PerfBench.baseline_engines(json: true))
    end
  end
end
