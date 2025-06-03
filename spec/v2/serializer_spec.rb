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

  let(:instances) { Blueprinter::V2::InstanceCache.new }

  it 'works with nil values' do
    widget = { name: nil, category: nil }

    result = described_class.new(widget_blueprint, {}, instances).object(widget)
    expect(result).to eq({
      name: nil,
      category: nil,
      parts: nil
    })
  end

  context 'extraction' do
    let(:name_of_extractor) do
      test = self
      Class.new(Blueprinter::V2::Extensions::Core::Extractor) do
        def initialize(prefix: 'Name') = @prefix = prefix

        def extract_value(ctx)
          case ctx.field
          when Blueprinter::V2::Fields::Field then "#{@prefix} of #{ctx.object[:name]}"
          when Blueprinter::V2::Fields::Object then { name: "#{@prefix} of #{ctx.object.dig(:category, :name)}" }
          when Blueprinter::V2::Fields::Collection then ctx.object[:parts].each_with_index.map { |_, i| { num: i + 1 } }
          end
        end
      end
    end

    let(:widget) do
      {
        name: 'Foo',
        extra: 'bar',
        category: { name: 'Bar', extra: 'bar' },
        parts: [{ num: 42, extra: 'bar' }, { num: 43 }]
      }
    end

    it 'extracts values and serialize nested Blueprints' do
      result = described_class.new(widget_blueprint, {}, instances).object(widget)
      expect(result).to eq({
        name: 'Foo',
        category: { name: 'Bar' },
        parts: [{ num: 42 }, { num: 43 }]
      })
    end

    it 'uses blocks' do
      test = self
      block_blueprint = Class.new(application_blueprint) do
        self.blueprint_name = 'BlockBlueprint'
        field(:name) { |ctx| "Name of #{ctx.object[:name]}" }
        object(:category, test.category_blueprint) { |ctx| { name: "Name of #{ctx.object.dig(:category, :name)}" } }
        collection(:parts, test.part_blueprint) { |ctx| ctx.object[:parts].each_with_index.map { |_, i| { num: i + 1 } } }
      end

      result = described_class.new(block_blueprint, {}, instances).object(widget)
      expect(result).to eq({
        name: 'Name of Foo',
        category: { name: 'Name of Bar' },
        parts: [{ num: 1 }, { num: 2 }]
      })
    end

    it 'uses field-level extractor (class)' do
      test = self
      blueprint = Class.new(application_blueprint) do
        self.blueprint_name = "BlockBlueprint"
        field :name, extractor: test.name_of_extractor
        object :category, test.category_blueprint, extractor: test.name_of_extractor
        collection :parts, test.part_blueprint, extractor: test.name_of_extractor
      end

      result = described_class.new(blueprint, {}, instances).object(widget)
      expect(result).to eq({
        name: 'Name of Foo',
        category: { name: 'Name of Bar' },
        parts: [{ num: 1 }, { num: 2 }]
      })
    end

    it 'uses field-level extractor (instance)' do
      test = self
      blueprint = Class.new(application_blueprint) do
        self.blueprint_name = "BlockBlueprint"
        extensions << test.name_of_extractor.new
        field :name, extractor: test.name_of_extractor.new(prefix: 'X')
        object :category, test.category_blueprint, extractor: test.name_of_extractor.new(prefix: 'Y')
        collection :parts, test.part_blueprint, extractor: test.name_of_extractor.new
      end

      result = described_class.new(blueprint, {}, instances).object(widget)
      expect(result).to eq({
        name: 'X of Foo',
        category: { name: 'Y of Bar' },
        parts: [{ num: 1 }, { num: 2 }]
      })
    end

    it 'uses blueprint extractor extension' do
      test = self
      blueprint = Class.new(application_blueprint) do
        self.blueprint_name = "BlockBlueprint"
        extensions << test.name_of_extractor.new
        extensions << test.name_of_extractor.new(prefix: 'X')
        field :name
        object :category, test.category_blueprint
        collection :parts, test.part_blueprint
      end

      result = described_class.new(blueprint, {}, instances).object(widget)
      expect(result).to eq({
        name: 'X of Foo',
        category: { name: 'X of Bar' },
        parts: [{ num: 1 }, { num: 2 }]
      })
    end
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

    result = described_class.new(widget_blueprint, {}, instances).object(widget)
    expect(result.to_json).to eq({
      category: { name: 'Bar' },
      name: 'Foo',
      parts: [{ num: 42 }, { num: 43 }]
    }.to_json)
  end

  it 'enables the if conditionals extension' do
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
      field :desc, if: ->(ctx) { ctx.options[:n] > 42 }
    end

    result = described_class.new(widget_blueprint, { n: 42 }, instances).object({ name: 'Foo', desc: 'Bar' })
    expect(result).to eq({ name: 'Foo' })
  end

  it 'enables the unless conditionals extension' do
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
      field :desc, unless: ->(ctx) { ctx.options[:n] > 42 }
    end

    result = described_class.new(widget_blueprint, { n: 43 }, instances).object({ name: 'Foo', desc: 'Bar' })
    expect(result).to eq({ name: 'Foo' })
  end

  it 'enables the default values extension' do
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
      field :desc, default: 'Description!'
    end

    result = described_class.new(widget_blueprint, {}, instances).object({ name: 'Foo' })
    expect(result).to eq({
      name: 'Foo',
      desc: 'Description!'
    })
  end

  it 'enables the exclude if empty extension' do
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      field :name, exclude_if_empty: true
      field :desc, exclude_if_empty: true
    end

    result = described_class.new(widget_blueprint, {}, instances).object({ name: 'Foo', desc: "" })
    expect(result).to eq({ name: 'Foo' })
  end

  it 'enables the exclude if nil extension' do
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      field :name, exclude_if_nil: true
      field :desc, exclude_if_nil: true
    end

    result = described_class.new(widget_blueprint, {}, instances).object({ name: 'Foo', desc: nil })
    expect(result).to eq({ name: 'Foo' })
  end

  it 'enables custom extensions' do
    ext1 = Class.new(Blueprinter::Extension) do
      def around_object_render(_) = yield
    end
    ext2 = Class.new(Blueprinter::Extension) do
      def around_collection_render(_) = yield
    end
    ext3 = Class.new(Blueprinter::Extension) do
      def around_object_serialization(_) = yield
    end
    category_blueprint.extensions << ext1 << ext2.new << -> { ext3.new }
    serializer = described_class.new(category_blueprint, {}, instances)

    expect(serializer.hooks.registered? :around_object_render).to be true
    expect(serializer.hooks.registered? :around_collection_render).to be true
    expect(serializer.hooks.registered? :around_object_serialization).to be true
  end

  it 'formats fields' do
    widget = { name: 'Foo', created_on: Date.new(2024, 10, 31) }
    result = described_class.new(widget_blueprint[:extended], {}, instances).object(widget)
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

    result = described_class.new(widget_blueprint[:extended], {}, instances).object(widget)
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

    result = described_class.new(widget_blueprint, {}, instances).object(widget)
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

    result = described_class.new(widget_blueprint, {}, instances).object(widget)
    expect(result).to eq({ name: 'Foo', category: nil })
  end

  it 'evaluates value hooks before exclusion hooks' do
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
      field :desc, default: 'Bar', if: ->(ctx) { !ctx.value.nil? }
    end
    widget = { name: 'Foo', desc: nil }

    result = described_class.new(widget_blueprint, {}, instances).object(widget)
    expect(result).to eq({ name: 'Foo', desc: 'Bar' })
  end

  it 'evaluates both ifs and unlesses' do
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      field :name, if: ->(ctx) { ctx.options[:n] > 42 }
      field :desc, unless: ->(ctx) { ctx.options[:n] < 43 }
      field :zorp,
        if: ->(ctx) { ctx.options[:n] > 40 },
        unless: ->(ctx) { ctx.options[:m] == 42 }
    end

    result = described_class.new(widget_blueprint, { n: 42, m: 42 }, instances).object(
      { name: 'Foo', desc: 'Bar', zorp: 'Zorp' }
    )
    expect(result).to eq({})
  end

  it 'runs blueprint_input hooks before anything else' do
    ext = Class.new(Blueprinter::Extension) do
      def blueprint_input(_ctx)
        { name: 'Foo' }
      end
    end
    widget_blueprint.extensions << ext.new

    result = described_class.new(widget_blueprint, {}, instances).object(
      { category: { name: 'Cat' }, parts: [{ num: 42 }] }
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

    result = described_class.new(widget_blueprint, {}, instances).object(
      { category: { name: 'Cat' }, parts: [{ num: 42 }] }
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

    result = described_class.new(widget_blueprint, {}, instances).object(widget)
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

    result = described_class.new(widget_blueprint, {}, instances).collection(widgets)
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

    result = described_class.new(blueprint, {}, instances).object(
      { description: 'A widget', category: { name: 'Cat' }, parts: [{ num: 42 }], name: 'Foo' }
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

    described_class.new(widget_blueprint, {}, instances).collection(
      [
        { name: 'A', description: 'Widget A', category: { name: 'Cat' }, parts: [{ num: 42 }, { num: 43 }] },
        { name: 'B', description: 'Widget B', category: { name: 'Cat' }, parts: [{ num: 43 }, { num: 44 }] },
      ]
    )

    expect(log).to eq [
      'blueprint_fields (WidgetBlueprint)',
      'prepare (WidgetBlueprint)',
      'blueprint_fields (CategoryBlueprint)',
      'prepare (CategoryBlueprint)',
      'blueprint_fields (PartBlueprint)',
      'prepare (PartBlueprint)'
    ]
  end

  it 'uses the same serializer and blueprint instances throughout, for a given blueprint' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      self.blueprint_name = 'Foo'
      field :name
      object :child, self
    end
    instances = Blueprinter::V2::InstanceCache.new
    def instances.cache = @cache

    serializer = instances[described_class, [blueprint, { foo: 'bar' }, instances]]
    res = serializer.object({ name: 'A', child: { name: 'B', child: { name: 'C' } } })
    expect(res).to eq({ name: 'A', child: { name: 'B', child: { name: 'C', child: nil } } })

    blueprint_serializers = instances.cache.select do |key, _val|
      key == described_class.object_id || (key.is_a?(Array) && key[0] == described_class.object_id)
    end
    expect(blueprint_serializers.size).to eq 1

    blueprint_instances = instances.cache.select do |key, _val|
      key == blueprint.object_id || (key.is_a?(Array) && key[0] == blueprint.object_id)
    end
    expect(blueprint_instances.size).to eq 1
  end
end
