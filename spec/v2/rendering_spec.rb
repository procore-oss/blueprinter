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
    end
  end

  let(:widget) { { name: 'Foo', category: { name: 'Bar' }, parts: [{ num: 42 }, { num: 43 }] } }

  it 'should auto-detect an object' do
    result = widget_blueprint.render(widget, {}).to_hash
    expect(result).to eq({
      name: 'Foo',
      cat: { name: 'Bar' },
      parts: [{ num: 42 }, { num: 43 }]
    })
  end

  it 'should auto-detect array collections' do
    result = widget_blueprint.render([widget], {}).to_hash
    expect(result).to eq([
      {
        name: 'Foo',
        cat: { name: 'Bar' },
        parts: [{ num: 42 }, { num: 43 }]
      }
    ])
  end
end
