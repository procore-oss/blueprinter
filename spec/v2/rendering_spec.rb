# frozen_string_literal: true

describe "Blueprinter::V2 Rendering" do
  let(:category_blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :name
    end
  end

  let(:part_blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :num
    end
  end

  let(:widget_blueprint) do
    test = self
    Class.new(Blueprinter::V2::Base) do
      field :name
      object :cat, test.category_blueprint, from: :category
      collection :parts, test.part_blueprint

      view :extended do
        field :description
      end
    end
  end

  let(:widget) { { name: 'Foo', description: 'About Foo', category: { name: 'Bar' }, parts: [{ num: 42 }, { num: 43 }] } }

  it 'auto-detects an object' do
    result = widget_blueprint.render(widget, {}).to_hash
    expect(result).to eq({
      name: 'Foo',
      cat: { name: 'Bar' },
      parts: [{ num: 42 }, { num: 43 }]
    })
  end

  it 'auto-detects array collections' do
    result = widget_blueprint.render([widget], {}).to_hash
    expect(result).to eq([
      {
        name: 'Foo',
        cat: { name: 'Bar' },
        parts: [{ num: 42 }, { num: 43 }]
      }
    ])
  end

  it 'renders a lazy enumerator' do
    enum = Enumerator.new do |y|
      y << widget
      y << widget
    end
    result = widget_blueprint.render(enum.lazy).to_hash
    expect(result).to eq([
      {
        name: 'Foo',
        cat: { name: 'Bar' },
        parts: [{ num: 42 }, { num: 43 }]
      },
      {
        name: 'Foo',
        cat: { name: 'Bar' },
        parts: [{ num: 42 }, { num: 43 }]
      }
    ])
  end

  it 'renders an object with options' do
    result = widget_blueprint.render_object(widget, { root: :data }).to_hash
    expect(result).to eq({
      data: {
        name: 'Foo',
        cat: { name: 'Bar' },
        parts: [{ num: 42 }, { num: 43 }]
      }
    })
  end

  it 'renders a collection with options' do
    result = widget_blueprint.render_collection([widget], { root: :data }).to_hash
    expect(result).to eq({
      data: [{
        name: 'Foo',
        cat: { name: 'Bar' },
        parts: [{ num: 42 }, { num: 43 }]
      }]
    })
  end

  it 'renders an object with the deprecated view option' do
    result = widget_blueprint.render_object(widget, { view: :extended }).to_hash
    expect(result).to eq({
      name: 'Foo',
      description: 'About Foo',
      cat: { name: 'Bar' },
      parts: [{ num: 42 }, { num: 43 }]
    })
  end

  it 'renders a collection with the deprecated view option' do
    result = widget_blueprint.render_collection([widget], { view: :extended }).to_hash
    expect(result).to eq([{
      name: 'Foo',
      description: 'About Foo',
      cat: { name: 'Bar' },
      parts: [{ num: 42 }, { num: 43 }]
    }])
  end

  it 'uses the same Context.store Hash throughout, for a given extension' do
    log_ext = Class.new(Blueprinter::Extension) do
      def initialize(log) = @log = log

      def input_collection(ctx)
        @log.clear
        ctx.store[:log] = @log
        ctx.object
      end
    end
    foo_ext = Class.new(log_ext) do
      def field_value(ctx)
        ctx.field.options[:foo]&.call(ctx)
        ctx.value
      end
      alias_method :object_value, :field_value
      alias_method :collection_value, :field_value
    end
    bar_ext = Class.new(log_ext) do
      def field_value(ctx)
        ctx.field.options[:bar]&.call(ctx)
        ctx.value
      end
      alias_method :object_value, :field_value
      alias_method :collection_value, :field_value
    end

    log_foo, log_bar = [], []
    application_blueprint = Class.new(Blueprinter::V2::Base) do
      extensions << foo_ext.new(log_foo) << bar_ext.new(log_bar)
    end
    category_blueprint = Class.new(application_blueprint) do
      field :name,
        foo: ->(ctx) { ctx.store[:log] << "Foo: #{ctx.value}" },
        bar: ->(ctx) { ctx.store[:log] << "Bar: #{ctx.value}" }
    end
    part_blueprint = Class.new(application_blueprint) do
      field :num,
        foo: ->(ctx) { ctx.store[:log] << "Foo: #{ctx.value}" },
        bar: ->(ctx) { ctx.store[:log] << "Bar: #{ctx.value}" }
    end
    widget_blueprint = Class.new(application_blueprint) do
      field :name,
        foo: ->(ctx) { ctx.store[:log] << "Foo: #{ctx.value}" },
        bar: ->(ctx) { ctx.store[:log] << "Bar: #{ctx.value}" }
      object :category, category_blueprint,
        foo: ->(ctx) { ctx.store[:log] << "Foo: #{ctx.value}" },
        bar: ->(ctx) { ctx.store[:log] << "Bar: #{ctx.value}" }
      collection :parts, part_blueprint,
        foo: ->(ctx) { ctx.store[:log] << "Foo: #{ctx.value}" },
        bar: ->(ctx) { ctx.store[:log] << "Bar: #{ctx.value}" }
    end

    widget_blueprint.render_collection([
      {
        name: 'Widget A',
        category: { name: 'Category 1' },
        parts: [{ num: 42 }, { num: 43 }]
      },
      {
        name: 'Widget B',
        category: { name: 'Category 2' },
        parts: [{ num: 43 }, { num: 44 }]
      },
    ]).to_hash

    expect(log_foo).to eq [
      'Foo: Widget A',
      "Foo: #{{ name: 'Category 1' }}",
      'Foo: Category 1',
      "Foo: #{[{ num: 42 }, { num: 43 }]}",
      'Foo: 42',
      'Foo: 43',
      'Foo: Widget B',
      "Foo: #{{ name: 'Category 2' }}",
      'Foo: Category 2',
      "Foo: #{[{ num: 43 }, { num: 44 }]}",
      'Foo: 43',
      'Foo: 44'
    ]

    expect(log_bar).to eq [
      'Bar: Widget A',
      "Bar: #{{ name: 'Category 1' }}",
      'Bar: Category 1',
      "Bar: #{[{ num: 42 }, { num: 43 }]}",
      'Bar: 42',
      'Bar: 43',
      'Bar: Widget B',
      "Bar: #{{ name: 'Category 2' }}",
      'Bar: Category 2',
      "Bar: #{[{ num: 43 }, { num: 44 }]}",
      'Bar: 43',
      'Bar: 44'
    ]
  end
end
