# frozen_string_literal: true

require 'active_support/json'

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
      association :cat, test.category_blueprint, source: :category
      association :parts, [test.part_blueprint]
    end
  end

  let(:widget) { { name: 'Foo', description: 'About Foo', category: { name: 'Bar' }, parts: [{ num: 42 }, { num: 43 }] } }

  let(:widget_struct) { Struct.new(:name, :description, :category, :parts) }

  it 'auto-detects an object' do
    result = widget_blueprint.render(widget, format: :hash)
    expect(result).to eq({
      name: 'Foo',
      cat: { name: 'Bar' },
      parts: [{ num: 42 }, { num: 43 }]
    })
  end

  it 'auto-detects array collections' do
    result = widget_blueprint.render([widget], format: :hash)
    expect(result).to eq([
      {
        name: 'Foo',
        cat: { name: 'Bar' },
        parts: [{ num: 42 }, { num: 43 }]
      }
    ])
  end

  it 'auto-detects a Struct as an object' do
    result = widget_blueprint.render(widget_struct.new(*widget.values_at(:name, :description, :category, :parts)), format: :hash)
    expect(result).to eq({
      name: 'Foo',
      cat: { name: 'Bar' },
      parts: [{ num: 42 }, { num: 43 }]
    })
  end

  it 'auto-detects a collection of Structs' do
    struct = widget_struct.new(*widget.values_at(:name, :description, :category, :parts))
    result = widget_blueprint.render([struct], format: :hash)
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
    result = widget_blueprint.render(enum.lazy, format: :hash)
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
    result = widget_blueprint.render_object(widget, { root: :data })
    expect(result).to eq({
      data: {
        name: 'Foo',
        cat: { name: 'Bar' },
        parts: [{ num: 42 }, { num: 43 }]
      }
    }.to_json)
  end

  it 'renders a collection with options' do
    result = widget_blueprint.render_collection([widget], { root: :data })
    expect(result).to eq({
      data: [{
        name: 'Foo',
        cat: { name: 'Bar' },
        parts: [{ num: 42 }, { num: 43 }]
      }]
    }.to_json)
  end

  it 'renders to JSON by default' do
    result = widget_blueprint.render(widget)
    expect(result).to eq({
      name: 'Foo',
      cat: { name: 'Bar' },
      parts: [{ num: 42 }, { num: 43 }]
    }.to_json)
  end

  it 'accepts options without braces' do
    expect(widget_blueprint.render(widget, root: :data, format: :hash)).to eq({
      data: {
        name: 'Foo',
        cat: { name: 'Bar' },
        parts: [{ num: 42 }, { num: 43 }]
      }
    })
    expect(widget_blueprint.render_object(widget, root: :data, format: :hash)).to have_key(:data)
    expect(widget_blueprint.render_collection([widget], root: :data, format: :hash)).to have_key(:data)
  end

  it 'accepts format in an options hash' do
    result = widget_blueprint.render(widget, { root: :data, format: :hash })
    expect(result).to eq({
      data: {
        name: 'Foo',
        cat: { name: 'Bar' },
        parts: [{ num: 42 }, { num: 43 }]
      }
    })
  end

  it 'removes format from the options and leaves the caller\'s Hash alone' do
    seen = nil
    blueprint = Class.new(Blueprinter::V2::Base) do
      field(:name) { |_obj, ctx| seen = ctx.options }
    end
    options = { root: :data, format: :hash }

    blueprint.render({}, options)
    expect(seen).to eq({ root: :data })
    expect(options).to eq({ root: :data, format: :hash })
    expect(options).not_to be_frozen
  end

  it 'responds to legacy render_as_hash' do
    result = widget_blueprint.render_as_hash(widget, { root: :data })
    expect(result).to eq({
      data: {
        name: 'Foo',
        cat: { name: 'Bar' },
        parts: [{ num: 42 }, { num: 43 }]
      }
    })
  end

  it 'responds to legacy render_as_json' do
    result = widget_blueprint.render_as_json(widget, { root: :data })
    expect(result).to eq({
      data: {
        name: 'Foo',
        cat: { name: 'Bar' },
        parts: [{ num: 42 }, { num: 43 }]
      }
    }.as_json)
  end
end
