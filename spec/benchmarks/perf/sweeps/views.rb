# frozen_string_literal: true

module PerfBench
  sweep 'views', 'Views', 'Baseline (widgets carry 10 extra fields for the views to add).' do
    hashes = -> { Fixtures.widgets(BASELINE_SIZE, width: 30) }

    scenario 'default view' do
      Setup.new(input: hashes, engines: PerfBench.baseline_engines)
    end

    scenario 'named view (+5 fields)' do
      extra = EXTRA.first(5)
      blueprint = Blueprints.widget { view(:extended) { fields(*extra) } }
      Setup.new(input: hashes, engines: [engine { |input| blueprint.render_as_hash(input, view: :extended) }])
    end

    scenario '3-level include_view chain, 2 exclusions' do
      a, b, c = EXTRA.each_slice(2).first(3)
      blueprint = Blueprints.widget do
        view(:a) { fields(*a) }
        view(:b) do
          include_view :a
          fields(*b)
        end
        view(:c) do
          include_view :b
          fields(*c)
          excludes :f00, :f01
        end
      end
      Setup.new(input: hashes, engines: [engine { |input| blueprint.render_as_hash(input, view: :c) }])
    end

    scenario '3 included views, 2 exclusions' do
      groups = EXTRA.each_slice(3).first(3)
      blueprint = Blueprints.widget do
        groups.each_with_index { |names, i| view(:"p#{i}") { fields(*names) } }
        view(:full) do
          include_views :p0, :p1, :p2
          excludes :f00, :f01
        end
      end
      Setup.new(input: hashes, engines: [engine { |input| blueprint.render_as_hash(input, view: :full) }])
    end
  end
end
