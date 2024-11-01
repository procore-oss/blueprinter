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

  it 'should render an object to a hash' do
    serializer = Blueprinter::V2::Serializer.new(widget_blueprint)
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new(widget, {}, serializer: serializer, collection: false)

    expect(render.to_hash).to eq({
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    })
  end

  it 'should render a collection to a hash' do
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

  it 'should render an object to JSON' do
    serializer = Blueprinter::V2::Serializer.new(widget_blueprint)
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new(widget, {}, serializer: serializer, collection: false)

    expect(render.to_json).to eq({
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    }.to_json)
  end

  it 'should render a collection to JSON' do
    serializer = Blueprinter::V2::Serializer.new(widget_blueprint)
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new([widget], {}, serializer: serializer, collection: true)

    expect(render.to_json).to eq([{
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    }].to_json)
  end

  it 'should call input hooks on objects' do
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

  it 'should call input hooks on collections' do
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
end
