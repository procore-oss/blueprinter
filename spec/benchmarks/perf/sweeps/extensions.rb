# frozen_string_literal: true

module PerfBench
  sweep 'transform', 'Output post-processing', 'Baseline with a transformer that adds one key.' do
    hashes = -> { Fixtures.widgets(BASELINE_SIZE) }

    scenario 'none' do
      Setup.new(input: hashes, engines: PerfBench.baseline_engines)
    end

    { 'root, 1 transformer' => [1, false], 'root, 3 transformers' => [3, false],
      'root and children, 1 each' => [1, true] }.each do |label, (count, children)|
      scenario label do
        add = ->(bp) { count.times { bp.transform Blueprints::KindTransformer } }
        company = children ? Blueprints.company { add.call(self) } : Blueprints.company
        part = children ? Blueprints.part { add.call(self) } : Blueprints.part
        blueprint = Blueprints.widget(company:, part:) { add.call(self) }
        Setup.new(input: hashes, engines: PerfBench.hash_engines(blueprint))
      end
    end
  end

  sweep 'extensions', 'Extensions',
        'Baseline with no-op `pre_render` extensions in `config.extensions`. `pre_render` runs for the root and for ' \
        'every association value.' do
    hashes = -> { Fixtures.widgets(BASELINE_SIZE) }

    [0, 1, 5].each do |count|
      scenario "#{count} pre_render extension#{'s' unless count == 1}",
               config: ->(c) { count.times { c.extensions << Blueprints::NoopPreRender.new } } do
        Setup.new(input: hashes, engines: PerfBench.baseline_engines)
      end
    end
  end

  sweep 'render_options', 'Render options',
        'Baseline rendered with this many option keys. Block rows add 5 block fields that read an option; the options ' \
        'are splatted into every block call.' do
    hashes = -> { Fixtures.widgets(BASELINE_SIZE) }

    [0, 20].each do |keys|
      options = OPTION_KEYS.first(keys).to_h { |k| [k, k.to_s] }

      scenario "#{keys} keys" do
        Setup.new(input: hashes, engines: PerfBench.hash_engines(Blueprints.widget, options:))
      end

      scenario "#{keys} keys, 5 block fields" do
        blueprint = Blueprints.widget { 5.times { |i| field(:"b#{i}") { |_obj, opts| opts[:opt_0] } } }
        Setup.new(input: hashes, engines: PerfBench.hash_engines(blueprint, options:))
      end
    end

    { 'association :options (Hash)' => { label: 'from parent' },
      'association :options (Proc of parent)' => ->(widget) { { label: widget[:f00] } } }.each do |label, assoc_opts|
      scenario label do
        company = Blueprints.company { field(:label) { |_obj, opts| opts[:label] } }
        blueprint = Blueprints.widget(company: nil) { association :company, blueprint: company, options: assoc_opts }
        Setup.new(input: hashes, engines: PerfBench.hash_engines(blueprint))
      end
    end
  end

  sweep 'output', 'Output path',
        'Baseline rendered to a Hash or to JSON. JSON rows set `config.generator` (and `method`). MultiJson uses its ' \
        'Oj adapter.' do
    hashes = -> { Fixtures.widgets(BASELINE_SIZE) }

    scenario 'Hash' do
      Setup.new(input: hashes, engines: PerfBench.baseline_engines)
    end

    scenario 'JSON (stdlib)' do
      Setup.new(input: hashes, engines: PerfBench.baseline_engines(json: true))
    end

    scenario 'JSON (Oj)', config: ->(c) { c.generator = Oj } do
      Setup.new(input: hashes, engines: PerfBench.baseline_engines(json: true))
    end

    scenario 'JSON (MultiJson)', requires: %i[multi_json], config: lambda { |c|
      c.generator = MultiJson
      c.method = :dump
    } do
      Setup.new(input: hashes, engines: PerfBench.baseline_engines(json: true))
    end

    scenario 'render_as_json (ActiveSupport)', note: 'ActiveSupport is loaded with ActiveRecord for the whole run.' do
      blueprint = Blueprints.widget
      Setup.new(input: hashes, engines: [engine { |input| blueprint.render_as_json(input) }])
    end
  end
end
