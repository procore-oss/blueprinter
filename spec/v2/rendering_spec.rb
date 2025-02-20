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

  it 'uses the same Context.store Hash throughout' do
    log_ext = Class.new(Blueprinter::Extension) do
      def initialize(log)
        @log = log
      end

      def input_collection(ctx)
        @log.clear
        ctx.store[:log] = @log
        ctx.object
      end
    end
    foo_ext = Class.new(Blueprinter::Extension) do
      def field_value(ctx)
        ctx.field.options[:foo]&.call(ctx)
        ctx.value
      end
      alias_method :object_value, :field_value
      alias_method :collection_value, :field_value
    end
    application_blueprint = Class.new(Blueprinter::V2::Base) do
      extensions << foo_ext.new
    end
    category_blueprint = Class.new(application_blueprint) do
      field :name, foo: ->(ctx) { ctx.store[:log] << ctx.value }
    end
    part_blueprint = Class.new(application_blueprint) do
      field :num, foo: ->(ctx) { ctx.store[:log] << ctx.value }
    end
    log = []
    widget_blueprint = Class.new(application_blueprint) do
      extensions << log_ext.new(log)
      field :name, foo: ->(ctx) { ctx.store[:log] << ctx.value }
      object :category, category_blueprint, foo: ->(ctx) { ctx.store[:log] << ctx.value }
      collection :parts, part_blueprint, foo: ->(ctx) { ctx.store[:log] << ctx.value }
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

    expect(log).to eq [
      'Widget A',
      { name: 'Category 1' },
      'Category 1',
      [{ num: 42 }, { num: 43 }],
      42,
      43,
      'Widget B',
      { name: 'Category 2' },
      'Category 2',
      [{ num: 43 }, { num: 44 }],
      43,
      44
    ]
  end
end
