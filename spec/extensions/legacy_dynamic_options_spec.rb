# frozen_string_literal: true

describe Blueprinter::Extensions::LegacyDynamicOptions do
  subject { described_class.new }
  let(:category_blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :name
      field(:val) { |_, ctx| ctx.options[:dynamic_val] }
    end
  end

  it 'applies a Hash to the options' do
    test = self
    blueprint = Class.new(Blueprinter::V2::Base) do
      add test.subject
      association :category, test.category_blueprint, options: { dynamic_val: 42 }
    end

    result = blueprint.render({ category: { name: 'Foo' } }).to_hash
    expect(result).to eq({ category: { name: 'Foo', val: 42 } })
  end

  it 'applies a Hash to the options (collections)' do
    test = self
    blueprint = Class.new(Blueprinter::V2::Base) do
      add test.subject
      association :categories, [test.category_blueprint], options: { dynamic_val: 42 }
    end

    result = blueprint.render({ categories: [{ name: 'Foo' }, { name: 'Bar' }] }).to_hash
    expect(result).to eq({ categories: [{ name: 'Foo', val: 42 }, { name: 'Bar', val: 42 }] })
  end

  it 'applies a Proc to the options' do
    test = self
    blueprint = Class.new(Blueprinter::V2::Base) do
      add test.subject
      association :category, test.category_blueprint, options: ->(widget) { { dynamic_val: widget.fetch(:id) + 1 } }
    end
    result = blueprint.render({ id: 41, category: { name: 'Foo' } }).to_hash
    expect(result).to eq({ category: { name: 'Foo', val: 42 } })
  end

  it 'applies a Proc to the options (collections)' do
    test = self
    blueprint = Class.new(Blueprinter::V2::Base) do
      add test.subject
      association :categories, [test.category_blueprint], options: ->(widget) { { dynamic_val: widget.fetch(:id) + 1 } }
    end
    result = blueprint.render({ id: 41, categories: [{ name: 'Foo' }] }).to_hash
    expect(result).to eq({ categories: [{ name: 'Foo', val: 42 }] })
  end

  it 'passes each object in a rendered collection to the Proc' do
    test = self
    blueprint = Class.new(Blueprinter::V2::Base) do
      add test.subject
      association :category, test.category_blueprint, options: ->(widget) { { dynamic_val: widget.fetch(:id) + 1 } }
    end

    result = blueprint.render([{ id: 41, category: { name: 'Foo' } }, { id: 99, category: { name: 'Bar' } }]).to_hash
    expect(result).to eq([
      { category: { name: 'Foo', val: 42 } },
      { category: { name: 'Bar', val: 100 } }
    ])
  end

  it 'passes each object in a rendered collection to the Proc (association collections)' do
    test = self
    blueprint = Class.new(Blueprinter::V2::Base) do
      add test.subject
      association :categories, [test.category_blueprint], options: ->(widget) { { dynamic_val: widget.fetch(:id) + 1 } }
    end

    result = blueprint.render([
      { id: 41, categories: [{ name: 'Foo' }, { name: 'Bar' }] },
      { id: 99, categories: [{ name: 'Baz' }] }
    ]).to_hash
    expect(result).to eq([
      { categories: [{ name: 'Foo', val: 42 }, { name: 'Bar', val: 42 }] },
      { categories: [{ name: 'Baz', val: 100 }] }
    ])
  end

  it 'applies the options to everything nested under the association' do
    test = self
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      association :category, test.category_blueprint
    end
    blueprint = Class.new(Blueprinter::V2::Base) do
      add test.subject
      association :widgets, [widget_blueprint], options: ->(order) { { dynamic_val: order.fetch(:id) + 1 } }
    end

    result = blueprint.render([
      { id: 41, widgets: [{ category: { name: 'Foo' } }] },
      { id: 99, widgets: [{ category: { name: 'Bar' } }] }
    ]).to_hash
    expect(result).to eq([
      { widgets: [{ category: { name: 'Foo', val: 42 } }] },
      { widgets: [{ category: { name: 'Bar', val: 100 } }] }
    ])
  end

  it "doesn't apply the options to other associations" do
    test = self
    blueprint = Class.new(Blueprinter::V2::Base) do
      add test.subject
      association :category_a, test.category_blueprint, options: { dynamic_val: 42 }
      association :category_b, test.category_blueprint, options: { dynamic_val: 43 }
      association :category_c, test.category_blueprint
    end

    result = blueprint.render({ category_a: { name: 'A' }, category_b: { name: 'B' }, category_c: { name: 'C' } }).to_hash
    expect(result).to eq(
      category_a: { name: 'A', val: 42 },
      category_b: { name: 'B', val: 43 },
      category_c: { name: 'C', val: nil }
    )
  end

  it "doesn't apply the options to the Blueprint that defines the association" do
    test = self
    blueprint = Class.new(Blueprinter::V2::Base) do
      add test.subject
      field(:val) { |_, ctx| ctx.options[:dynamic_val] }
      association :category, test.category_blueprint, options: { dynamic_val: 42 }
    end

    result = blueprint.render({ category: { name: 'Foo' } }).to_hash
    expect(result).to eq({ val: nil, category: { name: 'Foo', val: 42 } })
  end

  it 'merges the options over the ones passed to render' do
    test = self
    category_blueprint = Class.new(Blueprinter::V2::Base) do
      field(:val) { |_, ctx| [ctx.options[:dynamic_val], ctx.options[:from_render]] }
    end
    blueprint = Class.new(Blueprinter::V2::Base) do
      add test.subject
      association :category, category_blueprint, options: { dynamic_val: 42 }
    end

    result = blueprint.render({ category: {} }, from_render: 'foo', dynamic_val: 0).to_hash
    expect(result).to eq({ category: { val: [42, 'foo'] } })
  end

  it 'ignores :options on non-association fields' do
    test = self
    blueprint = Class.new(Blueprinter::V2::Base) do
      add test.subject
      field :name, options: { dynamic_val: 42 }
      association :category, test.category_blueprint
    end

    result = blueprint.render({ name: 'Foo', category: {} }).to_hash
    expect(result).to eq({ name: 'Foo', category: { name: nil, val: nil } })
  end

  it 'matches V1 behavior' do
    category_blueprint = Class.new(Blueprinter::Base) do
      field :name
      field(:val) { |_, options| options[:dynamic_val] }
    end
    v1 = Class.new(Blueprinter::Base) do
      field(:val) { |_, options| options[:dynamic_val] }
      association :categories, blueprint: category_blueprint, options: ->(widget) { { dynamic_val: widget[:id] + 1 } }
      association :other, blueprint: category_blueprint
    end

    test = self
    v2 = Class.new(Blueprinter::V2::Base) do
      add test.subject
      field(:val) { |_, ctx| ctx.options[:dynamic_val] }
      association :categories, [test.category_blueprint], options: ->(widget) { { dynamic_val: widget.fetch(:id) + 1 } }
      association :other, test.category_blueprint
    end

    objects = [
      { id: 41, categories: [{ name: 'Foo' }, { name: 'Bar' }], other: { name: 'Other' } },
      { id: 99, categories: [{ name: 'Baz' }], other: { name: 'Other' } }
    ]
    expect(v2.render(objects).to_hash).to eq(v1.render_as_hash(objects))
  end
end
