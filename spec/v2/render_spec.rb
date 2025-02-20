# frozen_string_literal: true

describe Blueprinter::V2::Render do
  let(:category_blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :name, from: :n
    end
  end

  let(:widget_blueprint) do
    test = self
    Class.new(Blueprinter::V2::Base) do
      field :name
      field :desc, from: :description
      object :category, test.category_blueprint
    end
  end

  it 'renders an object to a hash' do
    serializer = Blueprinter::V2::Serializer.new(widget_blueprint)
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new(widget, {}, serializer: serializer, collection: false)

    expect(render.to_hash).to eq({
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    })
  end

  it 'renders a collection to a hash' do
    serializer = Blueprinter::V2::Serializer.new(widget_blueprint)
    widgets = [
      { name: 'Foo', description: 'About', category: { n: 'Bar' } },
      { name: 'Foo 2', description: 'About 2', category: { n: 'Bar 2' } },
    ]
    render = described_class.new(widgets, {}, serializer: serializer, collection: true)

    expect(render.to_hash).to eq([
      {
        name: 'Foo',
        desc: 'About',
        category: { name: 'Bar' }
      },
      {
        name: 'Foo 2',
        desc: 'About 2',
        category: { name: 'Bar 2' }
      },
    ])
  end

  it 'renders an object to JSON' do
    serializer = Blueprinter::V2::Serializer.new(widget_blueprint)
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new(widget, {}, serializer: serializer, collection: false)

    expect(render.to_json).to eq({
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    }.to_json)
  end

  it 'renders a collection to JSON' do
    serializer = Blueprinter::V2::Serializer.new(widget_blueprint)
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new([widget], {}, serializer: serializer, collection: true)

    expect(render.to_json).to eq([{
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    }].to_json)
  end

  it 'renders to JSON and ignore the arg (for Rails `render json:`)' do
    serializer = Blueprinter::V2::Serializer.new(widget_blueprint)
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new([widget], {}, serializer: serializer, collection: true)

    expect(render.to_json({ junk: 'junk' })).to eq([{
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    }].to_json)
  end

  it 'responds to to_str with json' do
    serializer = Blueprinter::V2::Serializer.new(widget_blueprint)
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new(widget, {}, serializer: serializer, collection: false)

    expect(render.to_str).to eq({
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    }.to_json)
  end

  it 'calls the json hook' do
    ext = Class.new(Blueprinter::Extension) do
      def json(ctx)
        ctx.value.merge({ foo: 'bar' }).to_json
      end
    end
    widget_blueprint.extensions << ext.new
    serializer = Blueprinter::V2::Serializer.new(widget_blueprint)
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new(widget, {}, serializer: serializer, collection: false)

    expect(render.to_json).to eq({
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' },
      foo: 'bar'
    }.to_json)
  end

  it 'calls input hooks on objects' do
    ext = Class.new(Blueprinter::Extension) do
      def input_object(ctx)
        { name: ctx.object[:name] }
      end
    end
    widget_blueprint.extensions << ext.new
    serializer = Blueprinter::V2::Serializer.new(widget_blueprint)
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new(widget, {}, serializer: serializer, collection: false)

    expect(render.to_hash).to eq({
      name: 'Foo',
      desc: nil,
      category: nil
    })
  end

  it 'calls input hooks on collections' do
    ext = Class.new(Blueprinter::Extension) do
      def input_collection(ctx)
        ctx.object.map { |obj| { name: obj[:name] } }
      end
    end
    widget_blueprint.extensions << ext.new
    serializer = Blueprinter::V2::Serializer.new(widget_blueprint)
    widgets = [{ name: 'Foo', description: 'About', category: { n: 'Bar' } }]
    render = described_class.new(widgets, {}, serializer: serializer, collection: true)

    expect(render.to_hash).to eq([{
      name: 'Foo',
      desc: nil,
      category: nil
    }])
  end

  it 'calls output hooks for objects' do
    ext = Class.new(Blueprinter::Extension) do
      def output_object(ctx)
        { data: ctx.value }
      end
    end
    widget_blueprint.extensions << ext.new
    serializer = Blueprinter::V2::Serializer.new(widget_blueprint)
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new(widget, {}, serializer: serializer, collection: false)

    expect(render.to_hash).to eq({
      data: {
        name: 'Foo',
        desc: 'About',
        category: { name: 'Bar' }
      }
    })
  end

  it 'calls output hooks for collections' do
    ext = Class.new(Blueprinter::Extension) do
      def output_collection(ctx)
        { data: ctx.value }
      end
    end
    widget_blueprint.extensions << ext.new
    serializer = Blueprinter::V2::Serializer.new(widget_blueprint)
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new([widget], {}, serializer: serializer, collection: true)

    expect(render.to_hash).to eq({
      data: [{
        name: 'Foo',
        desc: 'About',
        category: { name: 'Bar' }
      }]
    })
  end

  it 'runs the around_render hook around all other render hooks' do
    ext = Class.new(Blueprinter::Extension) do
      def initialize(log)
        @log = log
      end

      def around_render(ctx)
        @log << 'around_render: a'
        yield
        @log << 'around_render: b'
      end

      def input_object(ctx)
        @log << 'input_object'
        ctx.object
      end

      def input_collection(ctx)
        @log << 'input_collection'
        ctx.object
      end

      def output_object(ctx)
        @log << 'output_object'
        ctx.value
      end

      def output_collection(ctx)
        @log << 'output_collection'
        ctx.value
      end
    end
    log = []
    category_blueprint.extensions << ext.new(log)
    serializer = Blueprinter::V2::Serializer.new(category_blueprint)
    result = described_class.new({ n: 'Foo' }, {}, serializer: serializer, collection: false).to_hash
    expect(result).to eq({ name: 'Foo' })
    expect(log).to eq ['around_render: a', 'input_object', 'output_object', 'around_render: b']

    log.clear
    result = described_class.new([{ n: 'Foo' }], {}, serializer: serializer, collection: true).to_hash
    expect(result).to eq([{ name: 'Foo' }])
    expect(log).to eq ['around_render: a', 'input_collection', 'output_collection', 'around_render: b']
  end
end
