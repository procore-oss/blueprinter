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

    result = described_class.new(widget_blueprint, {}, instances, store: {}, initial_depth: 1).object(widget, depth: 1)
    expect(result).to eq({
      name: nil,
      category: nil,
      parts: nil
    })
  end

  context 'extraction' do
    let(:name_of_extractor) do
      test = self
      Class.new(Blueprinter::Extension) do
        def initialize(prefix: 'Name') = @tmp_prefix = prefix

        def around_blueprint_init(ctx)
          @prefix = @tmp_prefix
          yield ctx
        end

        def around_field_value(ctx)
          name = ctx.object.fetch(ctx.field.from)
          "#{@prefix} of #{name}"
        end

        def around_object_value(ctx)
          obj = ctx.object.fetch(ctx.field.from)
          { name: "#{@prefix} of #{obj[:name]}" }
        end

        def around_collection_value(ctx)
          collection = ctx.object.fetch(ctx.field.from)
          collection.each_with_index.map { |_, i| { num: i + 1 } }
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
      result = described_class.new(widget_blueprint, {}, instances, store: {}, initial_depth: 1).object(widget, depth: 1)
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
        field(:name) { |obj, _ctx| "Name of #{obj[:name]}" }
        object(:category, test.category_blueprint) { |obj, _ctx| { name: "Name of #{obj.dig(:category, :name)}" } }
        collection(:parts, test.part_blueprint) { |obj, _ctx| obj[:parts].each_with_index.map { |_, i| { num: i + 1 } } }
      end

      result = described_class.new(block_blueprint, {}, instances, store: {}, initial_depth: 1).object(widget, depth: 1)
      expect(result).to eq({
        name: 'Name of Foo',
        category: { name: 'Name of Bar' },
        parts: [{ num: 1 }, { num: 2 }]
      })
    end

    it 'uses blueprint extractor extension' do
      test = self
      blueprint = Class.new(application_blueprint) do
        self.blueprint_name = "BlockBlueprint"
        extensions << test.name_of_extractor.new(prefix: 'X')
        field :name
        object :category, test.category_blueprint
        collection :parts, test.part_blueprint
      end

      result = described_class.new(blueprint, {}, instances, store: {}, initial_depth: 1).object(widget, depth: 1)
      expect(result).to eq({
        name: 'X of Foo',
        category: { name: 'X of Bar' },
        parts: [{ num: 1 }, { num: 2 }]
      })
    end
  end

  it 'enables the if conditionals extension' do
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
      field :desc, if: ->(_val, ctx) { ctx.options[:n] > 42 }
    end

    result = described_class.new(widget_blueprint, { n: 42 }, instances, store: {}, initial_depth: 1).object({ name: 'Foo', desc: 'Bar' }, depth: 1)
    expect(result).to eq({ name: 'Foo' })
  end

  it 'enables the unless conditionals extension' do
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
      field :desc, unless: ->(_val, ctx) { ctx.options[:n] > 42 }
    end

    result = described_class.new(widget_blueprint, { n: 43 }, instances, store: {}, initial_depth: 1).object({ name: 'Foo', desc: 'Bar' }, depth: 1)
    expect(result).to eq({ name: 'Foo' })
  end

  it 'enables the default values extension' do
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
      field :desc, default: 'Description!'
    end

    result = described_class.new(widget_blueprint, {}, instances, store: {}, initial_depth: 1).object({ name: 'Foo' }, depth: 1)
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

    result = described_class.new(widget_blueprint, {}, instances, store: {}, initial_depth: 1).object({ name: 'Foo', desc: "" }, depth: 1)
    expect(result).to eq({ name: 'Foo' })
  end

  it 'enables the exclude if nil extension' do
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      field :name, exclude_if_nil: true
      field :desc, exclude_if_nil: true
    end

    result = described_class.new(widget_blueprint, {}, instances, store: {}, initial_depth: 1).object({ name: 'Foo', desc: nil }, depth: 1)
    expect(result).to eq({ name: 'Foo' })
  end

  it 'enables custom extensions' do
    ext1 = Class.new(Blueprinter::Extension) do
      def around_serialize_object(ctx) = yield ctx
    end
    ext2 = Class.new(Blueprinter::Extension) do
      def around_serialize_collection(ctx) = yield ctx
    end
    ext3 = Class.new(Blueprinter::Extension) do
      def around_blueprint(ctx) = yield ctx
    end
    category_blueprint.extensions << ext1 << ext2.new << -> { ext3.new }
    serializer = described_class.new(category_blueprint, {}, instances, store: {}, initial_depth: 1)

    expect(serializer.hooks.registered? :around_serialize_object).to be true
    expect(serializer.hooks.registered? :around_serialize_collection).to be true
    expect(serializer.hooks.registered? :around_blueprint).to be true
  end

  it 'formats fields' do
    widget = { name: 'Foo', created_on: Date.new(2024, 10, 31) }
    result = described_class.new(widget_blueprint[:extended], {}, instances, store: {}, initial_depth: 1).object(widget, depth: 1)
    expect(result).to eq({
      category: nil,
      name: 'Foo',
      created_on: 'Thu Oct 31, 2024',
      parts: nil
    })
  end

  it 'calls nested around_field_value hooks, then formatters' do
    ext1 = Class.new(Blueprinter::Extension) do
      def around_field_value(ctx)
        value = yield ctx
        value == '?' ? skip : value
      end
    end
    ext2 = Class.new(Blueprinter::Extension) do
      def around_field_value(ctx)
        value = yield ctx
        value.is_a?(Date) ? value + 10 : '?'
      end
    end
    widget_blueprint.extensions << ext1.new << ext2.new
    widget = { name: 'Foo', created_on: Date.new(2024, 10, 31) }

    result = described_class.new(widget_blueprint[:extended], {}, instances, store: {}, initial_depth: 1).object(widget, depth: 1)
    expect(result).to eq({
      category: nil,
      created_on: 'Sun Nov 10, 2024',
      parts: nil
    })
  end

  it 'calls nested around_object_value hooks' do
    ext1 = Class.new(Blueprinter::Extension) do
      def around_object_value(ctx)
        value = yield ctx
        value[:name] == 'Bar' ? skip : value
      end
    end
    ext2 = Class.new(Blueprinter::Extension) do
      def around_object_value(_ctx)
        { name: 'Bar' }
      end
    end
    widget_blueprint.extensions << ext1.new << ext2.new
    widget = { name: 'Foo', category: { name: 'Cat' } }

    result = described_class.new(widget_blueprint, {}, instances, store: {}, initial_depth: 1).object(widget, depth: 1)
    expect(result).to eq({ name: 'Foo', parts: nil })
  end

  it 'calls nested around_collection_value hooks' do
    ext1 = Class.new(Blueprinter::Extension) do
      def around_collection_value(ctx) = yield(ctx) << { num: 43 }
    end
    ext2 = Class.new(Blueprinter::Extension) do
      def around_collection_value(ctx)
        value = yield ctx
        value.empty? ? skip : value
      end
    end
    ext3 = Class.new(Blueprinter::Extension) do
      def around_collection_value(ctx) = yield(ctx)[1..]
    end
    widget_blueprint.extensions << ext1.new << ext2.new << ext3.new

    widget = { name: 'Foo', parts: [{ num: 42 }] }
    result = described_class.new(widget_blueprint, {}, instances, store: {}, initial_depth: 1).object(widget, depth: 1)
    expect(result).to eq({ name: 'Foo', category: nil })

    widget = { name: 'Foo', parts: [{ num: 41 }, { num: 42 }] }
    result = described_class.new(widget_blueprint, {}, instances, store: {}, initial_depth: 1).object(widget, depth: 1)
    expect(result).to eq({ name: 'Foo', category: nil, parts: [{ num: 42 }, { num: 43 }] })
  end

  it 'evaluates value hooks before exclusion hooks' do
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
      field :desc, default: 'Bar', if: ->(val, _ctx) { !val.nil? }
    end
    widget = { name: 'Foo', desc: nil }

    result = described_class.new(widget_blueprint, {}, instances, store: {}, initial_depth: 1).object(widget, depth: 1)
    expect(result).to eq({ name: 'Foo', desc: 'Bar' })
  end

  it 'evaluates both ifs and unlesses' do
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      field :name, if: ->(_val, ctx) { ctx.options[:n] > 42 }
      field :desc, unless: ->(_val, ctx) { ctx.options[:n] < 43 }
      field :zorp,
        if: ->(_val, ctx) { ctx.options[:n] > 40 },
        unless: ->(_val, ctx) { ctx.options[:m] == 42 }
    end

    result = described_class.new(widget_blueprint, { n: 42, m: 42 }, instances, store: {}, initial_depth: 1).object(
      { name: 'Foo', desc: 'Bar', zorp: 'Zorp' },
      depth: 1
    )
    expect(result).to eq({})
  end

  it 'runs around_serialize_object and around_blueprint' do
    ext = Class.new(Blueprinter::Extension) do
      def initialize(log)
        @log = log
      end

      def around_blueprint_init(ctx)
        @log << 'around_blueprint_init: a'
        yield ctx
        @log << 'around_blueprint_init: b'
      end

      def around_serialize_object(ctx)
        @log << "around_serialize_object (#{ctx.object[:name]}): a"
        res = yield ctx
        @log << "around_serialize_object (#{ctx.object[:name]}): b"
        res
      end

      def around_blueprint(ctx)
        @log << "around_blueprint (#{ctx.object[:name]}): a"
        res = yield ctx
        @log << "around_blueprint (#{ctx.object[:name]}): b"
        res
      end
    end
    log = []
    widget_blueprint.extensions << ext.new(log)
    widget = { name: 'Foo', category: { name: 'Bar' }, parts: [{ num: 42 }, { num: 43 }] }

    result = described_class.new(widget_blueprint, {}, instances, store: {}, initial_depth: 1).object(widget, depth: 1)
    expect(result).to eq(widget)
    expect(log).to eq [
      'around_blueprint_init: a',
      'around_blueprint_init: b',
      'around_serialize_object (Foo): a',
      'around_blueprint (Foo): a',
      'around_blueprint (Foo): b',
      'around_serialize_object (Foo): b',
    ]
  end

  it 'runs around_serialize_collection and around_blueprint' do
    ext = Class.new(Blueprinter::Extension) do
      def initialize(log)
        @log = log
      end

      def around_blueprint_init(ctx)
        @log << 'around_blueprint_init: a'
        yield ctx
        @log << 'around_blueprint_init: b'
      end

      def around_serialize_collection(ctx)
        @log << "around_serialize_collection (#{ctx.object.map { |x| x[:name] }.join(',')}): a"
        res = yield ctx
        @log << "around_serialize_collection (#{ctx.object.map { |x| x[:name] }.join(',')}): b"
        res
      end

      def around_blueprint(ctx)
        @log << "around_blueprint (#{ctx.object[:name]}): a"
        res = yield ctx
        @log << "around_blueprint (#{ctx.object[:name]}): b"
        res
      end
    end
    log = []
    widget_blueprint.extensions << ext.new(log)
    widgets = [
      { name: 'Foo', category: { name: 'Bar' }, parts: [{ num: 42 }, { num: 43 }] },
      { name: 'Bar', category: { name: 'Bar' }, parts: [{ num: 43 }, { num: 43 }] },
    ]

    result = described_class.new(widget_blueprint, {}, instances, store: {}, initial_depth: 1).collection(widgets, depth: 1)
    expect(result).to eq(widgets)
    expect(log).to eq [
      'around_blueprint_init: a',
      'around_blueprint_init: b',
      'around_serialize_collection (Foo,Bar): a',
      'around_blueprint (Foo): a',
      'around_blueprint (Foo): b',
      'around_blueprint (Bar): a',
      'around_blueprint (Bar): b',
      'around_serialize_collection (Foo,Bar): b',
    ]
  end

  it 'puts fields in the order they were defined' do
    blueprint = Class.new(widget_blueprint) do
      field :description
    end

    result = described_class.new(blueprint, {}, instances, store: {}, initial_depth: 1).object(
      { description: 'A widget', category: { name: 'Cat' }, parts: [{ num: 42 }], name: 'Foo' },
      depth: 1
    )
    expect(result.to_json).to eq({
      name: 'Foo',
      category: { name: 'Cat' },
      parts: [{ num: 42 }],
      description: 'A widget'
      }.to_json)
  end

  it 'only runs around_blueprint_init once per blueprint' do
    log = []
    ext = Class.new(Blueprinter::Extension) do
      def initialize(log) = @log = log
      def around_blueprint_init(ctx)
        @log << "around_blueprint_init (#{ctx.blueprint.class})"
        yield ctx
      end
    end
    application_blueprint.extensions << ext.new(log)

    described_class.new(widget_blueprint, {}, instances, store: {}, initial_depth: 1).collection(
      [
        { name: 'A', description: 'Widget A', category: { name: 'Cat' }, parts: [{ num: 42 }, { num: 43 }] },
        { name: 'B', description: 'Widget B', category: { name: 'Cat' }, parts: [{ num: 43 }, { num: 44 }] },
      ],
      depth: 1
    )

    expect(log).to eq [
      'around_blueprint_init (WidgetBlueprint)',
      'around_blueprint_init (CategoryBlueprint)',
      'around_blueprint_init (PartBlueprint)',
    ]
  end

  it "raises if around_blueprint_init doesn't yield" do
    ext = Class.new(Blueprinter::Extension) do
      def around_blueprint_init(ctx) = true
    end
    application_blueprint.extensions << ext.new

    expect do
      described_class.new(widget_blueprint, {}, instances, store: {}, initial_depth: 1).object({}, depth: 1)
    end.to raise_error(Blueprinter::Errors::ExtensionHook, /did not yield/)
  end

  it 'uses the same serializer and blueprint instances throughout, for a given blueprint' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      self.blueprint_name = 'Foo'
      field :name
      object :child, self
    end
    instances = Blueprinter::V2::InstanceCache.new
    def instances.serializers = @serializers
    def instances.blueprints = @blueprints

    serializer = instances.serializer(blueprint, { foo: 'bar' }, {}, 1)
    res = serializer.object({ name: 'A', child: { name: 'B', child: { name: 'C' } } }, depth: 1)
    expect(res).to eq({ name: 'A', child: { name: 'B', child: { name: 'C', child: nil } } })

    blueprint_serializers = instances.serializers.count
    expect(blueprint_serializers).to eq 1

    blueprint_instances = instances.blueprints.count
    expect(blueprint_instances).to eq 1
  end

  it 'passes objects information about the parent' do
    ext = Class.new(Blueprinter::Extension) do
      def initialize(log) = @log = log

      def around_serialize_object(ctx)
        if ctx.parent
          @log << "Object Parent Blueprint: #{ctx.parent.blueprint}"
          @log << "Object Parent field: #{ctx.parent.field.name}"
          @log << "Object Parent object: #{ctx.parent.object[:name]}"
        end
        yield ctx
      end

      def around_serialize_collection(ctx)
        if ctx.parent
          @log << "Collection Parent Blueprint: #{ctx.parent.blueprint}"
          @log << "Collection Parent field: #{ctx.parent.field.name}"
          @log << "Collection Parent object: #{ctx.parent.object[:name]}"
        end
        yield ctx
      end
    end
    log = []
    category_blueprint.extensions << ext.new(log)
    part_blueprint.extensions << ext.new(log)
    serializer = described_class.new(widget_blueprint, {}, instances, store: {}, initial_depth: 1)

    widget = { name: 'Foo', category: { name: 'Bar' }, parts: [{ num: 42 }] }
    result = serializer.object(widget, depth: 1)
    expect(log).to eq [
      "Object Parent Blueprint: WidgetBlueprint",
      "Object Parent field: category",
      "Object Parent object: Foo",
      "Collection Parent Blueprint: WidgetBlueprint",
      "Collection Parent field: parts",
      "Collection Parent object: Foo"
    ]
  end
end
