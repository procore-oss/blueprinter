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

  let(:instances) { Blueprinter::V2::InstanceCache.new }

  it 'renders an object to a hash' do
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new(widget, {}, blueprint: widget_blueprint, collection: false, instances:)

    expect(render.to_hash).to eq({
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    })
  end

  it 'renders a collection to a hash' do
    widgets = [
      { name: 'Foo', description: 'About', category: { n: 'Bar' } },
      { name: 'Foo 2', description: 'About 2', category: { n: 'Bar 2' } },
    ]
    render = described_class.new(widgets, {}, blueprint: widget_blueprint, collection: true, instances:)

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
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new(widget, {}, blueprint: widget_blueprint, collection: false, instances:)

    expect(render.to_json).to eq({
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    }.to_json)
  end

  it 'renders a collection to JSON' do
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new([widget], {}, blueprint: widget_blueprint, collection: true, instances:)

    expect(render.to_json).to eq([{
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    }].to_json)
  end

  it 'uses the last json hook' do
    json_ext = Class.new(Blueprinter::Extension) do
      def initialize(name, log)
        @name = name
        @log = log
      end

      def json(ctx)
        @log << "#{@name}: custom json!"
        JSON.dump ctx.result.reject { |_k, v| v.nil? }
      end
    end
    log = []
    widget_blueprint.extensions << json_ext.new('A', log)
    widget_blueprint.extensions << json_ext.new('B', log)

    render = described_class.new({ name: 'Foo' }, {}, blueprint: widget_blueprint, collection: false, instances:)

    expect(render.to_json).to eq '{"name":"Foo"}'
    expect(log).to eq ['B: custom json!']
  end

  it 'renders to JSON and ignores the arg (for Rails `render json:`)' do
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new([widget], {}, blueprint: widget_blueprint, collection: true, instances:)

    expect(render.to_json({ junk: 'junk' })).to eq([{
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    }].to_json)
  end

  it 'responds to to_str with json' do
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new(widget, {}, blueprint: widget_blueprint, collection: false, instances:)

    expect(render.to_str).to eq({
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    }.to_json)
  end

  it 'calls the json hook' do
    ext = Class.new(Blueprinter::Extension) do
      def json(ctx)
        ctx.result.merge({ foo: 'bar' }).to_json
      end
    end
    widget_blueprint.extensions << ext.new
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new(widget, {}, blueprint: widget_blueprint, collection: false, instances:)

    expect(render.to_json).to eq({
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' },
      foo: 'bar'
    }.to_json)
  end
end
