# frozen_string_literal: true

module EngineBench
  module Blueprints
    # A blueprint per tree level, each with 5 fields and (above the bottom level) a `children` collection.
    module Tree
      module_function

      def v1(depth)
        child = depth > 1 ? v1(depth - 1) : nil
        names = Fixtures.field_names(4)
        Class.new(Blueprinter::Base) do
          identifier :id
          fields(*names)
          association :children, blueprint: child if child
        end
      end

      def v2(depth, app = Blueprints::V2.app)
        return unless EngineBench.v2?

        child = depth > 1 ? v2(depth - 1, app) : nil
        names = Fixtures.field_names(4)
        Class.new(app) do
          self.blueprint_name = "Level#{depth}Blueprint"
          field :id
          fields(*names)
          association :children, [child] if child
        end
      end
    end
  end

  sweep 'depth', 'Nesting depth',
        '100 root objects, each node with 5 fields and 3 children (a collection association) down to the given depth.' do
    [1, 2, 3, 4].each do |depth|
      scenario depth do
        v1 = Blueprints::Tree.v1(depth)
        v2 = Blueprints::Tree.v2(depth)
        Setup.new(input: -> { Fixtures.tree(BASELINE_SIZE, depth:, fanout: 3) }, engines: EngineBench.hash_engines(v1, v2))
      end
    end
  end

  sweep 'fanout', 'Children per parent', '100 root objects, depth 2, with this many children each.' do
    [1, 3, 10, 30].each do |fanout|
      scenario fanout do
        v1 = Blueprints::Tree.v1(2)
        v2 = Blueprints::Tree.v2(2)
        Setup.new(input: -> { Fixtures.tree(BASELINE_SIZE, depth: 2, fanout:) }, engines: EngineBench.hash_engines(v1, v2))
      end
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
        v1_company = Blueprints::V1.company
        v1_part = Blueprints::V1.part
        v1 = Blueprints::V1.widget(company: nil, part: nil) do
          objects.times { |i| association :"company_#{i}", blueprint: v1_company }
          collections.times { |i| association :"parts_#{i}", blueprint: v1_part }
        end
        app = Blueprints::V2.app
        v2_company = Blueprints::V2.company(app)
        v2_part = Blueprints::V2.part(app)
        v2 = Blueprints::V2.widget(app, company: nil, part: nil) do
          objects.times { |i| association :"company_#{i}", v2_company }
          collections.times { |i| association :"parts_#{i}", [v2_part] }
        end
        Setup.new(input:, engines: EngineBench.hash_engines(v1, v2))
      end
    end
  end

  sweep 'repeated_children', 'Repeated children',
        'Baseline, but the 100 widgets share this many company objects (the same object referenced by many parents).' do
    { 'distinct (100 companies)' => nil, 'shared (10 companies)' => 10, 'shared (1 company)' => 1 }.each do |label, n|
      scenario label do
        Setup.new(input: -> { Fixtures.widgets(BASELINE_SIZE, companies: n) }, engines: EngineBench.baseline_engines)
      end
    end
  end
end
