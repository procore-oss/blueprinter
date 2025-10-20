# frozen_string_literal: true

require 'json'

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

      view :extended do
        field :long_desc do |_ctx|
          'Long desc'
        end
      end
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

  it 'renders to JSON and ignores the arg (for Rails `render json:`)' do
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new([widget], {}, blueprint: widget_blueprint, collection: true, instances:)

    expect(render.to_json({ junk: 'junk' })).to eq([{
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    }].to_json)
  end

  it 'runs around_result around the entire result' do
    ext = Class.new(Blueprinter::Extension) do
      def around_result(ctx)
        case ctx.format
        when :json
          ctx.format = :hash
          result = yield(ctx).merge({ foo: 'bar' })
          JSON.dump result
        else
          yield ctx
        end
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

  it 'respects the view option' do
    widget_blueprint.extensions << Blueprinter::Extensions::ViewOption.new
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new(widget, { view: :extended }, blueprint: widget_blueprint, collection: false, instances:)

    expect(render.to_hash).to eq({
      name: 'Foo',
      desc: 'About',
      long_desc: 'Long desc',
      category: { name: 'Bar' },
    })
  end
end
