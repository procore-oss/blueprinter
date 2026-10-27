# frozen_string_literal: true

module EngineBench
  sweep 'transform', 'Output post-processing',
        'Baseline with a transformer that adds one key. V1 `transform`; V2 an `around_blueprint` extension; ' \
        'V2+Legacy the same V1 transformer through LegacyTransformer.',
        engines: LEGACY_ENGINES do
    hashes = -> { Fixtures.widgets(BASELINE_SIZE) }

    scenario 'none' do
      Setup.new(input: hashes, engines: EngineBench.baseline_engines)
    end

    { 'root, 1 transformer' => [1, false], 'root, 3 transformers' => [3, false],
      'root and children, 1 each' => [1, true] }.each do |label, (count, children)|
      scenario label do
        v1_ext = ->(bp) { count.times { bp.transform Blueprints::KindTransformer } }
        v2_ext = ->(bp) { count.times { bp.add Blueprints::KindExtension.new } }
        legacy_ext = ->(bp) { bp.add Blueprinter::Extensions::LegacyTransformer.new(*[Blueprints::KindTransformer] * count) }
        v1 = Blueprints::V1.widget(company: children ? Blueprints::V1.company { v1_ext.call(self) } : Blueprints::V1.company,
                                   part: children ? Blueprints::V1.part { v1_ext.call(self) } : Blueprints::V1.part) do
          v1_ext.call(self)
        end
        build_v2 = lambda do |ext|
          app = Blueprints::V2.app
          company = Blueprints::V2.company(app) { ext.call(self) if children }
          part = Blueprints::V2.part(app) { ext.call(self) if children }
          Blueprints::V2.widget(app, company:, part:) { ext.call(self) }
        end
        Setup.new(input: hashes, engines: EngineBench.hash_engines(v1, build_v2.call(v2_ext), build_v2.call(legacy_ext)))
      end
    end
  end

  sweep 'hooks', 'Extensions and hooks',
        'Baseline with no-op extensions on every blueprint (V1: global `config.extensions`; V2: `add` on the ' \
        'application blueprint). V1 has only `pre_render`, so rows without a V1 equivalent run plain V1.' do
    hashes = -> { Fixtures.widgets(BASELINE_SIZE) }
    object_hooks = Blueprints::NoopHooks::OBJECT_HOOKS
    field_hooks = Blueprints::NoopHooks::FIELD_HOOKS

    # [V1 pre_render extensions, V2 setup, features required]. Rows that add V2-only hooks have no V1 equivalent: V1 would
    # render the same as `none`, so they're skipped when V2 isn't available.
    v2_only = %i[v2]
    rows = {
      'none' => [0, proc {}, []],
      '1 non-field hook of each kind' => [1, proc { add Blueprints::NoopHooks.new(object_hooks) }, v2_only],
      '1 hook of each kind (incl. field)' => [1, proc { add Blueprints::NoopHooks.new }, []],
      '5 hooks of each kind' => [5, proc { 5.times { add Blueprints::NoopHooks.new } }, []],
      'around_field_value only' => [0, proc { add Blueprints::NoopHooks.new([:around_field_value]) }, v2_only],
      'around_hook timer + 1 of each kind' => [1, proc { add Blueprints::HookTimer.new, Blueprints::NoopHooks.new },
                                               v2_only],
      'OpenTelemetry (no-op tracer)' => [0, proc { add Blueprinter::Extensions::OpenTelemetry.new('engine-bench') },
                                         %i[v2 opentelemetry]],
      'OpenTelemetry + 1 of each kind' => [1, proc do
        add Blueprinter::Extensions::OpenTelemetry.new('engine-bench'), Blueprints::NoopHooks.new
      end, %i[v2 opentelemetry]]
    }
    rows.each do |label, (pre_renders, v2_setup, requires)|
      note = pre_renders.zero? ? 'V1: no extension.' : "V1: #{pre_renders} no-op `pre_render` extension(s)."
      note += " V2 field hooks: #{field_hooks.join(', ')}." if label.include?('of each kind') && !label.include?('non-field')
      scenario label, note:, requires:,
                      v1_config: ->(c) { pre_renders.times { c.extensions << Blueprints::NoopPreRender.new } } do
        v1 = Blueprints::V1.widget
        v2 = Blueprints::V2.widget(Blueprints::V2.app(&v2_setup))
        Setup.new(input: hashes, engines: EngineBench.hash_engines(v1, v2))
      end
    end
  end

  sweep 'render_options', 'Render options',
        'Baseline rendered with this many option keys. Block rows add 5 block fields that read an option (V1 ' \
        '`|obj, options|`, V2 `|obj, ctx|`); V1 splats the options into every block call.',
        engines: LEGACY_ENGINES do
    hashes = -> { Fixtures.widgets(BASELINE_SIZE) }

    [0, 20].each do |keys|
      options = OPTION_KEYS.first(keys).to_h { |k| [k, k.to_s] }
      scenario "#{keys} keys" do
        v1 = Blueprints::V1.widget
        v2 = Blueprints::V2.widget
        Setup.new(input: hashes, engines: EngineBench.hash_engines(v1, v2, options:))
      end

      scenario "#{keys} keys, 5 block fields" do
        v1 = Blueprints::V1.widget { 5.times { |i| field(:"b#{i}") { |_obj, opts| opts[:opt_0] } } }
        v2 = Blueprints::V2.widget { 5.times { |i| field(:"b#{i}") { |_obj, ctx| ctx.options[:opt_0] } } }
        Setup.new(input: hashes, engines: EngineBench.hash_engines(v1, v2, options:))
      end
    end

    { 'association :options (Hash)' => { label: 'from parent' },
      'association :options (Proc of parent)' => ->(widget) { { label: widget[:f00] } } }.each do |label, assoc_opts|
      scenario label, note: 'V2 has no per-association options; V2+Legacy uses LegacyDynamicOptions on the widget.' do
        v1_company = Blueprints::V1.company { field(:label) { |_obj, opts| opts[:label] } }
        v1 = Blueprints::V1.widget(company: nil) { association :company, blueprint: v1_company, options: assoc_opts }
        app = Blueprints::V2.app
        legacy_company = Blueprints::V2.company(app) { field(:label) { |_obj, ctx| ctx.options[:label] } }
        legacy = Blueprints::V2.widget(app, company: nil) do
          add Blueprinter::Extensions::LegacyDynamicOptions.new
          association :company, legacy_company, options: assoc_opts
        end
        Setup.new(input: hashes, engines: EngineBench.hash_engines(v1, nil, legacy))
      end
    end
  end

  sweep 'output', 'Output path',
        'Baseline rendered to a Hash or to JSON. V1 sets `config.generator` (and `method`); V2 uses `to_json` ' \
        '(stdlib JSON), the bundled MultiJson extension, or a bench-local `around_result` extension calling ' \
        '`Oj.generate`. MultiJson uses its Oj adapter.' do
    hashes = -> { Fixtures.widgets(BASELINE_SIZE) }

    scenario 'Hash' do
      Setup.new(input: hashes, engines: EngineBench.baseline_engines)
    end

    scenario 'JSON (stdlib)' do
      Setup.new(input: hashes, engines: EngineBench.baseline_engines(json: true))
    end

    scenario 'JSON (Oj)', v1_config: ->(c) { c.generator = Oj } do
      v1 = Blueprints::V1.widget
      v2 = Blueprints::V2.widget(Blueprints::V2.app { add Blueprints::OjResult.new })
      Setup.new(input: hashes, engines: EngineBench.json_engines(v1, v2))
    end

    scenario 'JSON (MultiJson)', requires: %i[multi_json], v1_config: lambda { |c|
      c.generator = MultiJson
      c.method = :dump
    } do
      v1 = Blueprints::V1.widget
      v2 = Blueprints::V2.widget(Blueprints::V2.app { add Blueprinter::Extensions::MultiJson.new })
      Setup.new(input: hashes, engines: EngineBench.json_engines(v1, v2))
    end

    scenario 'render_as_json (ActiveSupport)', note: 'ActiveSupport is loaded with ActiveRecord for the whole run.' do
      v1 = Blueprints::V1.widget
      v2 = Blueprints::V2.widget
      Setup.new(input: hashes, engines: [
        engine('V1') { |input| v1.render_as_json(input) },
        engine('V2') { |input| v2.render_as_json(input) }
      ])
    end
  end
end
