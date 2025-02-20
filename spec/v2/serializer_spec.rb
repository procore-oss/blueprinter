# frozen_string_literal: true

require 'date'
require 'json'

describe Blueprinter::V2::Serializer do
  let(:application_blueprint) { Class.new(Blueprinter::V2::Base) }

  let(:category_blueprint) do
    Class.new(application_blueprint) do
      self.blueprint_name = "CategoryBlueprint"
      field :name
    end
  end

  let(:part_blueprint) do
    Class.new(application_blueprint) do
      self.blueprint_name = "PartBlueprint"
      field :num
    end
  end

  let(:widget_blueprint) do
    test = self
    Class.new(application_blueprint) do
      self.blueprint_name = "WidgetBlueprint"
      field :name
      object :category, test.category_blueprint
      collection :parts, test.part_blueprint

      view :extended do
        format(Date) { |date| date.strftime('%a %b %e, %Y') }
        field :created_on
      end
    end
  end

  let(:instance_cache) { Blueprinter::V2::InstanceCache.new }

  it 'works with nil values' do
    test = self
    widget = { name: nil, category: nil }

    result = described_class.new(widget_blueprint).object(widget, {}, instance_cache, {})
    expect(result).to eq({
      name: nil,
      category: nil,
      parts: nil
    })
  end

  it 'extracts values and serialize nested Blueprints' do
    test = self
    widget = {
      name: 'Foo',
      extra: 'bar',
      category: { name: 'Bar', extra: 'bar' },
      parts: [{ num: 42, extra: 'bar' }, { num: 43 }]
    }

    result = described_class.new(widget_blueprint).object(widget, {}, instance_cache, {})
    expect(result).to eq({
      name: 'Foo',
      category: { name: 'Bar' },
      parts: [{ num: 42 }, { num: 43 }]
    })
  end

  it 'respects the last blueprint_fields hook' do
    ext1 = Class.new(Blueprinter::Extension) do
      def blueprint_fields(_ctx) = raise 'Should not be called'
    end
    ext2 = Class.new(Blueprinter::Extension) do
      def blueprint_fields(ctx)
        ctx.blueprint.class.reflections[:default].ordered.sort_by(&:name)
      end
    end
    widget_blueprint.extensions << ext1.new
    widget_blueprint.extensions << ext2.new
    widget = {
      name: 'Foo',
      category: { name: 'Bar' },
      parts: [{ num: 42 }, { num: 43 }]
    }

    result = described_class.new(widget_blueprint).object(widget, {}, instance_cache, {})
    expect(result.to_json).to eq({
      category: { name: 'Bar' },
      name: 'Foo',
      parts: [{ num: 42 }, { num: 43 }]
    }.to_json)
  end

  it 'formats fields' do
    widget = { name: 'Foo', created_on: Date.new(2024, 10, 31) }
    result = described_class.new(widget_blueprint[:extended]).object(widget, {}, instance_cache, {})
    expect(result).to eq({
      category: nil,
      name: 'Foo',
      created_on: 'Thu Oct 31, 2024',
      parts: nil
    })
  end

  it 'calls field_value hooks, then formatters, then exclude_field? hooks' do
    ext = Class.new(Blueprinter::Extension) do
      def field_value(ctx)
        case ctx.value
        when Date then ctx.value + 10
        else '?'
        end
      end

      def exclude_field?(ctx)
        ctx.value == '?'
      end
    end
    widget_blueprint.extensions << ext.new
    widget = { name: 'Foo', created_on: Date.new(2024, 10, 31) }

    result = described_class.new(widget_blueprint[:extended]).object(widget, {}, instance_cache, {})
    expect(result).to eq({
      category: nil,
      created_on: 'Sun Nov 10, 2024',
      parts: nil
    })
  end

  it 'calls object_value hooks then exclude_object? hooks' do
    ext = Class.new(Blueprinter::Extension) do
      def object_value(_ctx)
        { name: 'Bar' }
      end

      def exclude_object?(ctx)
        ctx.value[:name] == 'Bar'
      end
    end
    widget_blueprint.extensions << ext.new
    widget = { name: 'Foo', category: { name: 'Cat' } }

    result = described_class.new(widget_blueprint).object(widget, {}, instance_cache, {})
    expect(result).to eq({ name: 'Foo', parts: nil })
  end

  it 'calls collection_value hooks then exclude_collection? hooks' do
    ext = Class.new(Blueprinter::Extension) do
      def collection_value(_ctx)
        []
      end

      def exclude_collection?(ctx)
        ctx.value.empty?
      end
    end
    widget_blueprint.extensions << ext.new
    widget = { name: 'Foo', parts: [{ num: 42 }] }

    result = described_class.new(widget_blueprint).object(widget, {}, instance_cache, {})
    expect(result).to eq({ name: 'Foo', category: nil })
  end

  it 'runs blueprint_input hooks before anything else' do
    ext = Class.new(Blueprinter::Extension) do
      def blueprint_input(_ctx)
        { name: 'Foo' }
      end
    end
    widget_blueprint.extensions << ext.new

    result = described_class.new(widget_blueprint).object(
      { category: { name: 'Cat' }, parts: [{ num: 42 }] },
      {},
      instance_cache,
      {}
    )
    expect(result).to eq({ name: 'Foo', category: nil, parts: nil })
  end

  it 'runs blueprint_output hooks after everything else' do
    ext = Class.new(Blueprinter::Extension) do
      def blueprint_output(_ctx)
        { name: 'Foo' }
      end
    end
    widget_blueprint.extensions << ext.new

    result = described_class.new(widget_blueprint).object(
      { category: { name: 'Cat' }, parts: [{ num: 42 }] },
      {},
      instance_cache,
      {}
    )
    expect(result).to eq({ name: 'Foo' })
  end

  it 'runs around_object_serialization around all other serializer hooks' do
    ext = Class.new(Blueprinter::Extension) do
      def initialize(log)
        @log = log
      end

      def around_object_serialization(ctx)
        @log << "around_object_serialization (#{ctx.object[:name]}): a"
        yield
        @log << "around_object_serialization (#{ctx.object[:name]}): b"
      end

      def prepare(ctx)
        @log << 'prepare'
      end

      def blueprint_input(ctx)
        @log << 'blueprint_input'
        ctx.object
      end

      def blueprint_output(ctx)
        @log << 'blueprint_output'
        ctx.result
      end
    end
    log = []
    widget_blueprint.extensions << ext.new(log)
    widget = { name: 'Foo', category: { name: 'Bar' }, parts: [{ num: 42 }, { num: 43 }] }

    result = described_class.new(widget_blueprint).object(widget, {}, instance_cache, {})
    expect(result).to eq(widget)
    expect(log).to eq [
      'prepare',
      'around_object_serialization (Foo): a',
      'blueprint_input',
      'blueprint_output',
      'around_object_serialization (Foo): b',
    ]
  end

  it 'runs around_collection_serialization around all other serializer hooks' do
    ext = Class.new(Blueprinter::Extension) do
      def initialize(log)
        @log = log
      end

      def around_collection_serialization(ctx)
        @log << "around_collection_serialization (#{ctx.object.map { |x| x[:name] }.join(',')}): a"
        yield
        @log << "around_collection_serialization (#{ctx.object.map { |x| x[:name] }.join(',')}): b"
      end

      def prepare(ctx)
        @log << 'prepare'
      end

      def blueprint_input(ctx)
        @log << 'blueprint_input'
        ctx.object
      end

      def blueprint_output(ctx)
        @log << 'blueprint_output'
        ctx.result
      end
    end
    log = []
    widget_blueprint.extensions << ext.new(log)
    widgets = [
      { name: 'Foo', category: { name: 'Bar' }, parts: [{ num: 42 }, { num: 43 }] },
      { name: 'Bar', category: { name: 'Bar' }, parts: [{ num: 43 }, { num: 43 }] },
    ]

    result = described_class.new(widget_blueprint).collection(widgets, {}, instance_cache, {})
    expect(result).to eq(widgets)
    expect(log).to eq [
      'prepare',
      'around_collection_serialization (Foo,Bar): a',
      'blueprint_input',
      'blueprint_output',
      'blueprint_input',
      'blueprint_output',
      'around_collection_serialization (Foo,Bar): b',
    ]
  end

  it 'puts fields in the order they were defined' do
    blueprint = Class.new(widget_blueprint) do
      field :description
    end

    result = described_class.new(blueprint).object(
      { description: 'A widget', category: { name: 'Cat' }, parts: [{ num: 42 }], name: 'Foo' },
      {},
      instance_cache,
      {}
    )
    expect(result.to_json).to eq({
      name: 'Foo',
      category: { name: 'Cat' },
      parts: [{ num: 42 }],
      description: 'A widget'
      }.to_json)
  end

  it 'only runs prepare and blueprint_fields once per blueprint' do
    log = []
    ext = Class.new(Blueprinter::Extension) do
      def initialize(log) = @log = log
      def prepare(ctx) = @log << "prepare (#{ctx.blueprint.class})"
      def blueprint_fields(ctx)
        @log << "blueprint_fields (#{ctx.blueprint.class})"
        ctx.blueprint.class.reflections[:default].ordered
      end
    end
    application_blueprint.extensions << ext.new(log)

    described_class.new(widget_blueprint).collection(
      [
        { name: 'A', description: 'Widget A', category: { name: 'Cat' }, parts: [{ num: 42 }, { num: 43 }] },
        { name: 'B', description: 'Widget B', category: { name: 'Cat' }, parts: [{ num: 43 }, { num: 44 }] },
      ],
      {},
      instance_cache,
      {}
    )

    expect(log).to eq [
      'prepare (WidgetBlueprint)',
      'blueprint_fields (WidgetBlueprint)',
      'prepare (CategoryBlueprint)',
      'blueprint_fields (CategoryBlueprint)',
      'prepare (PartBlueprint)',
      'blueprint_fields (PartBlueprint)'
    ]
  end
end
