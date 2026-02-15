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
      association :cat, test.category_blueprint, from: :category
      association :parts, [test.part_blueprint]
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
    result = widget_blueprint.render_object(widget, { root: :data }).to_json
    expect(result).to eq({
      data: {
        name: 'Foo',
        cat: { name: 'Bar' },
        parts: [{ num: 42 }, { num: 43 }]
      }
    }.to_json)
  end

  it 'renders a collection with options' do
    result = widget_blueprint.render_collection([widget], { root: :data }).to_json
    expect(result).to eq({
      data: [{
        name: 'Foo',
        cat: { name: 'Bar' },
        parts: [{ num: 42 }, { num: 43 }]
      }]
    }.to_json)
  end
end
