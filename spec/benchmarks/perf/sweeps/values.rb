# frozen_string_literal: true

module PerfBench
  sweep 'sparsity', 'Nil values',
        'Baseline with a fraction of the 20 fields nil, kept as nil or dropped with `exclude_if_nil` on each field.' do
    [0.0, 0.5, 0.9].each do |ratio|
      [false, true].each do |exclude|
        scenario "#{(ratio * 100).round}% nil#{', exclude_if_nil' if exclude}" do
          blueprint = Blueprints.widget(fields: false) do
            NAMES.each { |n| exclude ? field(n, exclude_if_nil: true) : field(n) }
          end
          input = -> { Fixtures.widgets(BASELINE_SIZE, nil_ratio: ratio) }
          Setup.new(input:, engines: PerfBench.hash_engines(blueprint))
        end
      end
    end
  end

  sweep 'defaults', 'Defaults', 'Baseline with `default:` (and `default_if:`) on all 20 fields.' do
    scenario 'no default' do
      Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE) }, engines: PerfBench.baseline_engines)
    end

    { 'default, value present' => 0.0, 'default, value nil (applied)' => 1.0 }.each do |label, ratio|
      scenario label do
        blueprint = Blueprints.widget(fields: false) { NAMES.each { |n| field n, default: 'n/a' } }
        Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE, nil_ratio: ratio) },
                  engines: PerfBench.hash_engines(blueprint))
      end
    end

    { 'default_if, not applied' => 'value', 'default_if, applied (empty string)' => '' }.each do |label, value|
      scenario label, note: '`default_if: Blueprinter::EMPTY_STRING`.' do
        input = lambda do
          Fixtures.widgets(BASELINE_SIZE, type: :string).each { |w| NAMES.each { |n| w[n] = value.empty? ? +'' : w[n] } }
        end
        blueprint = Blueprints.widget(fields: false) do
          NAMES.each { |n| field n, default: 'n/a', default_if: Blueprinter::EMPTY_STRING }
        end
        Setup.new(input:, engines: PerfBench.hash_engines(blueprint))
      end
    end
  end

  sweep 'value_types', 'Value types',
        'Baseline with all 20 fields of one type. Formatted rows: `config.datetime_format` or the field option.' do
    { 'String' => :string, 'Integer' => :integer, 'BigDecimal' => :decimal, 'Time, unformatted' => :time,
      'Date, unformatted' => :date }.each do |label, type|
      scenario label do
        Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE, type:) }, engines: PerfBench.baseline_engines)
      end
    end

    scenario 'Time, formatted (global)', config: ->(c) { c.datetime_format = TIME_FORMAT } do
      Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE, type: :time) }, engines: PerfBench.baseline_engines)
    end

    scenario 'Time, formatted (field option)' do
      blueprint = Blueprints.widget(fields: false) { NAMES.each { |n| field n, datetime_format: TIME_FORMAT } }
      Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE, type: :time) }, engines: PerfBench.hash_engines(blueprint))
    end

    scenario 'Date, formatted (global)', config: ->(c) { c.datetime_format = DATE_FORMAT } do
      Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE, type: :date) }, engines: PerfBench.baseline_engines)
    end

    scenario 'Integer, global datetime_format set', note: 'Values that are not dates, with a format configured.',
                                                     config: ->(c) { c.datetime_format = TIME_FORMAT } do
      Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE, type: :integer) }, engines: PerfBench.baseline_engines)
    end
  end
end
