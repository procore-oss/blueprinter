# frozen_string_literal: true

module EngineBench
  sweep 'sparsity', 'Nil values',
        'Baseline with a fraction of the 20 fields nil, kept as nil or dropped with exclude_if_nil (V1: on each ' \
        'field; V2: `set :exclude_if_nil, true` on the widget blueprint).' do
    [0.0, 0.5, 0.9].each do |ratio|
      [false, true].each do |exclude|
        scenario "#{(ratio * 100).round}% nil#{', exclude_if_nil' if exclude}" do
          v1 = Blueprints::V1.widget(fields: false) do
            NAMES.each { |n| exclude ? field(n, exclude_if_nil: true) : field(n) }
          end
          v2 = Blueprints::V2.widget do
            set :exclude_if_nil, true if exclude
          end
          input = -> { Fixtures.widgets(BASELINE_SIZE, nil_ratio: ratio) }
          Setup.new(input:, engines: EngineBench.hash_engines(v1, v2))
        end
      end
    end
  end

  sweep 'defaults', 'Defaults', 'Baseline with `default:` (and `default_if:`) on all 20 fields.',
        engines: LEGACY_ENGINES do
    scenario 'no default' do
      Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE) }, engines: EngineBench.baseline_engines)
    end

    { 'default, value present' => 0.0, 'default, value nil (applied)' => 1.0 }.each do |label, ratio|
      scenario label do
        v1 = Blueprints::V1.widget(fields: false) { NAMES.each { |n| field n, default: 'n/a' } }
        v2 = Blueprints::V2.widget(fields: false) { NAMES.each { |n| field n, default: 'n/a' } }
        Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE, nil_ratio: ratio) }, engines: EngineBench.hash_engines(v1, v2))
      end
    end

    { 'default_if, not applied' => 'value', 'default_if, applied (empty string)' => '' }.each do |label, value|
      scenario label, note: 'V1 and V2+Legacy use `default_if: Blueprinter::EMPTY_STRING`; V2 uses a Proc.' do
        input = lambda do
          Fixtures.widgets(BASELINE_SIZE, type: :string).each { |w| NAMES.each { |n| w[n] = value.empty? ? +'' : w[n] } }
        end
        v1 = Blueprints::V1.widget(fields: false) do
          NAMES.each { |n| field n, default: 'n/a', default_if: Blueprinter::EMPTY_STRING }
        end
        v2 = Blueprints::V2.widget(fields: false) do
          NAMES.each { |n| field n, default: 'n/a', default_if: ->(_ctx, v) { v.to_s.empty? } }
        end
        legacy = Blueprints::V2.widget(fields: false) do
          add Blueprinter::Extensions::LegacyOptions.new
          NAMES.each { |n| field n, default: 'n/a', default_if: Blueprinter::EMPTY_STRING }
        end
        Setup.new(input:, engines: EngineBench.hash_engines(v1, v2, legacy))
      end
    end
  end

  sweep 'value_types', 'Value types',
        'Baseline with all 20 fields of one type. Formatted rows: V1 `config.datetime_format` (or the field option), ' \
        'V2 `format(Time)` / `format(Date)` on the widget blueprint.' do
    { 'String' => :string, 'Integer' => :integer, 'BigDecimal' => :decimal, 'Time, unformatted' => :time,
      'Date, unformatted' => :date }.each do |label, type|
      scenario label do
        Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE, type:) }, engines: EngineBench.baseline_engines)
      end
    end

    scenario 'Time, formatted (global)', v1_config: ->(c) { c.datetime_format = TIME_FORMAT } do
      v1 = Blueprints::V1.widget
      v2 = Blueprints::V2.widget { format(Time) { |t| t.strftime(TIME_FORMAT) } }
      Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE, type: :time) }, engines: EngineBench.hash_engines(v1, v2))
    end

    scenario 'Time, formatted (field option)' do
      v1 = Blueprints::V1.widget(fields: false) { NAMES.each { |n| field n, datetime_format: TIME_FORMAT } }
      v2 = Blueprints::V2.widget { format(Time) { |t| t.strftime(TIME_FORMAT) } }
      Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE, type: :time) }, engines: EngineBench.hash_engines(v1, v2))
    end

    scenario 'Date, formatted (global)', v1_config: ->(c) { c.datetime_format = DATE_FORMAT } do
      v1 = Blueprints::V1.widget
      v2 = Blueprints::V2.widget { format(Date) { |d| d.strftime(DATE_FORMAT) } }
      Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE, type: :date) }, engines: EngineBench.hash_engines(v1, v2))
    end

    scenario 'Integer, V2 formatter defined for Time', note: 'V2 checks every plain value against its formatters ' \
                                                             'once any formatter is defined.' do
      v1 = Blueprints::V1.widget
      v2 = Blueprints::V2.widget { format(Time) { |t| t.strftime(TIME_FORMAT) } }
      Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE, type: :integer) }, engines: EngineBench.hash_engines(v1, v2))
    end
  end
end
