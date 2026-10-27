# frozen_string_literal: true

module PerfBench
  module Blueprints
    # A blueprint per tree level, each with 5 fields and (above the bottom level) a `children` collection.
    def self.tree(depth)
      child = depth > 1 ? tree(depth - 1) : nil
      names = Fixtures.field_names(4)
      Class.new(Blueprinter::Base) do
        identifier :id
        fields(*names)
        association :children, blueprint: child if child
      end
    end
  end

  sweep 'depth', 'Nesting depth',
        '100 root objects, each node with 5 fields and 3 children (a collection association) down to the given depth.' do
    [1, 2, 3, 4].each do |depth|
      scenario depth do
        Setup.new(input: -> { Fixtures.tree(BASELINE_SIZE, depth:, fanout: 3) },
                  engines: PerfBench.hash_engines(Blueprints.tree(depth)))
      end
    end
  end

  sweep 'fanout', 'Children per parent',
        '100 root objects, depth 2, with this many children each. The last row is one root with 1,000 children: ' \
        'one wide collection rather than many small ones.' do
    [1, 3, 10, 30].each do |fanout|
      scenario fanout do
        Setup.new(input: -> { Fixtures.tree(BASELINE_SIZE, depth: 2, fanout:) },
                  engines: PerfBench.hash_engines(Blueprints.tree(2)))
      end
    end

    scenario '1,000 (1 root)' do
      Setup.new(input: -> { Fixtures.tree(1, depth: 2, fanout: 1_000) }, engines: PerfBench.hash_engines(Blueprints.tree(2)))
    end
  end

  sweep 'association_kind', 'Object vs collection associations',
        '100 widgets with 20 fields and the given associations (each child has 3 fields). Rows with the same child ' \
        'count separate per-association cost from per-child cost.' do
    {
      'none' => [0, 0, 0],
      '1 object' => [1, 0, 0],
      '5 objects' => [5, 0, 0],
      '1 collection x 1 child' => [0, 1, 1],
      '1 collection x 5 children' => [0, 1, 5],
      '5 collections x 1 child' => [0, 5, 1]
    }.each do |label, (objects, collections, children)|
      scenario label do
        input = lambda do
          Fixtures.widgets(BASELINE_SIZE, parts: nil, company: false).each do |w|
            objects.times { |i| w[:"company_#{i}"] = Fixtures.company(w[:id] + i) }
            collections.times { |i| w[:"parts_#{i}"] = Array.new(children) { |c| Fixtures.part(w[:id], (i * 10) + c) } }
          end
        end
        company = Blueprints.company
        part = Blueprints.part
        blueprint = Blueprints.widget(company: nil, part: nil) do
          objects.times { |i| association :"company_#{i}", blueprint: company }
          collections.times { |i| association :"parts_#{i}", blueprint: part }
        end
        Setup.new(input:, engines: PerfBench.hash_engines(blueprint))
      end
    end
  end

  sweep 'repeated_children', 'Repeated children',
        'Baseline, but the 100 widgets share this many company objects (the same object referenced by many parents).' do
    { 'distinct (100 companies)' => nil, 'shared (10 companies)' => 10, 'shared (1 company)' => 1 }.each do |label, n|
      scenario label do
        Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE, companies: n) }, engines: PerfBench.baseline_engines)
      end
    end
  end
end
