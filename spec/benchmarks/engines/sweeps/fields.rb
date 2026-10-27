# frozen_string_literal: true

module EngineBench
  sweep 'field_kinds', 'Field kinds',
        'Baseline as plain objects (attr_reader) with all 20 fields of one kind. Plain objects rather than Hashes, ' \
        'because Symbol#to_proc blocks and extractors call methods on the object.',
        engines: LEGACY_ENGINES do
    poros = -> { Fixtures.convert(Fixtures.widgets(BASELINE_SIZE), :poro) }

    scenario 'plain' do
      Setup.new(input: poros, engines: EngineBench.baseline_engines)
    end

    scenario 'renamed', note: 'V1 `name:`, V2 `source:`, V2+Legacy `name:` through LegacyOptions.' do
      v1 = Blueprints::V1.widget(fields: false) { NAMES.each { |n| field n, name: :"out_#{n}" } }
      v2 = Blueprints::V2.widget(fields: false) { NAMES.each { |n| field :"out_#{n}", source: n } }
      legacy = Blueprints::V2.widget(fields: false) do
        add Blueprinter::Extensions::LegacyOptions.new
        NAMES.each { |n| field n, name: :"out_#{n}" }
      end
      Setup.new(input: poros, engines: EngineBench.hash_engines(v1, v2, legacy))
    end

    scenario 'block (1 arg)', note: 'V1 and V2 `{ |obj| ... }`.' do
      v1 = Blueprints::V1.widget(fields: false) { NAMES.each { |n| field(n) { |obj| obj.public_send(n) } } }
      v2 = Blueprints::V2.widget(fields: false) { NAMES.each { |n| field(n) { |obj| obj.public_send(n) } } }
      Setup.new(input: poros, engines: EngineBench.hash_engines(v1, v2))
    end

    scenario 'block (2 args)', note: 'V1 `{ |obj, options| ... }`; V2 `{ |obj, ctx| ... }`, which needs a field context.' do
      v1 = Blueprints::V1.widget(fields: false) { NAMES.each { |n| field(n) { |obj, _options| obj.public_send(n) } } }
      v2 = Blueprints::V2.widget(fields: false) { NAMES.each { |n| field(n) { |obj, _ctx| obj.public_send(n) } } }
      Setup.new(input: poros, engines: EngineBench.hash_engines(v1, v2))
    end

    scenario 'Symbol#to_proc', note: 'V2 calls field blocks with (object, context) when their arity is not 0 or 1, ' \
                                     'and a Symbol#to_proc block forwards both to the method.' do
      v1 = Blueprints::V1.widget(fields: false) { NAMES.each { |n| field(n, &n) } }
      v2 = Blueprints::V2.widget(fields: false) { NAMES.each { |n| field(n, &n) } }
      Setup.new(input: poros, engines: EngineBench.hash_engines(v1, v2))
    end

    scenario 'custom extractor', note: 'V1 uses an extractor instance; V2+Legacy needs a class (LegacyOptions calls ' \
                                       '`.new` on every extraction); V2 has no extractor option (see the block rows).' do
      v1 = Blueprints::V1.widget(fields: false) { NAMES.each { |n| field n, extractor: EXTRACTOR } }
      legacy = Blueprints::V2.widget(fields: false) do
        add Blueprinter::Extensions::LegacyOptions.new
        NAMES.each { |n| field n, extractor: Blueprints::PassThroughExtractor }
      end
      Setup.new(input: poros, engines: EngineBench.hash_engines(v1, nil, legacy))
    end
  end

  sweep 'conditions', 'Conditions',
        'Baseline with a condition on all 20 fields. 50% rows skip every other field. Global/blueprint-level: V1 ' \
        '`config.if`, which every V1 field checks; V2 `set :if` on the application blueprint, inherited by every ' \
        'blueprint.',
        engines: LEGACY_ENGINES do
    hashes = -> { Fixtures.widgets(BASELINE_SIZE) }

    scenario 'none' do
      Setup.new(input: hashes, engines: EngineBench.baseline_engines)
    end

    [0, 50].each do |skip|
      skipped = skip.zero? ? [] : HALF
      scenario "Proc if, #{skip}% skipped", note: 'V2+Legacy uses V1-style 3-argument Procs.' do
        v1 = Blueprints::V1.widget(fields: false) do
          NAMES.each { |n| field n, if: ->(_name, _obj, _opts) { !skipped.include?(n) } }
        end
        v2 = Blueprints::V2.widget(fields: false) do
          NAMES.each { |n| field n, if: ->(_ctx) { !skipped.include?(n) } }
        end
        legacy = Blueprints::V2.widget(fields: false) do
          add Blueprinter::Extensions::LegacyOptions.new
          NAMES.each { |n| field n, if: ->(_name, _obj, _opts) { !skipped.include?(n) } }
        end
        Setup.new(input: hashes, engines: EngineBench.hash_engines(v1, v2, legacy))
      end

      scenario "Symbol if, #{skip}% skipped" do
        v1 = Blueprints::V1.widget(fields: false) do
          define_singleton_method(:show?) { |name, _obj, _opts| !skipped.include?(name) }
          NAMES.each { |n| field n, if: :show? }
        end
        v2 = Blueprints::V2.widget(fields: false) do
          define_method(:show?) { |ctx| !skipped.include?(ctx.field.name) }
          NAMES.each { |n| field n, if: :show? }
        end
        Setup.new(input: hashes, engines: EngineBench.hash_engines(v1, v2))
      end

      v1_if = ->(name, _obj, _opts) { !skipped.include?(name) }
      scenario "global if, #{skip}% skipped", v1_config: ->(c) { c.if = v1_if } do
        v1 = Blueprints::V1.widget
        v2 = Blueprints::V2.widget(Blueprints::V2.app { set :if, ->(ctx) { !skipped.include?(ctx.field.name) } })
        legacy_app = Blueprints::V2.app do
          add Blueprinter::Extensions::LegacyOptions.new
          set :if, v1_if
        end
        Setup.new(input: hashes, engines: EngineBench.hash_engines(v1, v2, Blueprints::V2.widget(legacy_app)))
      end
    end

    scenario 'Proc unless, 0% skipped' do
      v1 = Blueprints::V1.widget(fields: false) { NAMES.each { |n| field n, unless: ->(_name, _obj, _opts) { false } } }
      v2 = Blueprints::V2.widget(fields: false) { NAMES.each { |n| field n, unless: ->(_ctx) { false } } }
      Setup.new(input: hashes, engines: EngineBench.hash_engines(v1, v2))
    end
  end
end
