# frozen_string_literal: true

module EngineBench
  sweep 'views', 'Views',
        'Baseline (widgets carry 10 extra fields for the views to add). V2+Legacy renders the root blueprint with ' \
        'V1-style `view:` through LegacyOptions.',
        engines: LEGACY_ENGINES do
    hashes = -> { Fixtures.widgets(BASELINE_SIZE, width: 30) }

    scenario 'default view' do
      Setup.new(input: hashes, engines: EngineBench.baseline_engines)
    end

    scenario 'named view (+5 fields)' do
      extra = EXTRA.first(5)
      v1 = Blueprints::V1.widget { view(:extended) { fields(*extra) } }
      v2 = Blueprints::V2.widget { view(:extended) { fields(*extra) } }
      legacy = Blueprints::V2.widget do
        add Blueprinter::Extensions::LegacyOptions.new
        view(:extended) { fields(*extra) }
      end
      Setup.new(input: hashes, engines: [
        engine('V1') { |input| v1.render_as_hash(input, view: :extended) },
        engine('V2') { |input| v2[:extended].render(input).to_hash },
        engine('V2+Legacy') { |input| legacy.render(input, view: :extended).to_hash }
      ])
    end

    scenario '3-level chain, 2 exclusions', note: 'V1 `include_view` chain; V2 nested views (`Blueprint[:a][:b][:c]`).' do
      a, b, c = EXTRA.each_slice(2).first(3)
      v1 = Blueprints::V1.widget do
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
      nested = proc do
        view :a do
          fields(*a)
          view :b do
            fields(*b)
            view :c do
              fields(*c)
              exclude :f00, :f01
            end
          end
        end
      end
      v2 = Blueprints::V2.widget(&nested)
      legacy = Blueprints::V2.widget do
        add Blueprinter::Extensions::LegacyOptions.new
        instance_exec(&nested)
      end
      Setup.new(input: hashes, engines: [
        engine('V1') { |input| v1.render_as_hash(input, view: :c) },
        engine('V2') { |input| v2[:a][:b][:c].render(input).to_hash },
        engine('V2+Legacy') { |input| legacy.render(input, view: :'a.b.c').to_hash }
      ])
    end

    scenario '3 included views, 2 exclusions', note: 'V1 `include_views` of three sibling views; V2 `use` of three ' \
                                                     'partials.' do
      groups = EXTRA.each_slice(3).first(3)
      v1 = Blueprints::V1.widget do
        groups.each_with_index { |names, i| view(:"p#{i}") { fields(*names) } }
        view(:full) do
          include_views :p0, :p1, :p2
          excludes :f00, :f01
        end
      end
      partials = proc do
        groups.each_with_index { |names, i| partial(:"p#{i}") { fields(*names) } }
        view(:full) do
          use :p0, :p1, :p2
          exclude :f00, :f01
        end
      end
      v2 = Blueprints::V2.widget(&partials)
      legacy = Blueprints::V2.widget do
        add Blueprinter::Extensions::LegacyOptions.new
        instance_exec(&partials)
      end
      Setup.new(input: hashes, engines: [
        engine('V1') { |input| v1.render_as_hash(input, view: :full) },
        engine('V2') { |input| v2[:full].render(input).to_hash },
        engine('V2+Legacy') { |input| legacy.render(input, view: :full).to_hash }
      ])
    end
  end
end
