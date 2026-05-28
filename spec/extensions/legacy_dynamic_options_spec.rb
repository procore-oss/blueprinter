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
      extensions { |exts| exts << test.subject }
      association :category, test.category_blueprint, options: { dynamic_val: 42 }
    end

    result = blueprint.render({ category: { name: 'Foo' } }).to_hash
    expect(result).to eq({ category: { name: 'Foo', val: 42 } })
  end

  it 'applies a Proc to the options' do
    test = self
    blueprint = Class.new(Blueprinter::V2::Base) do
      extensions { |exts| exts << test.subject }
      association :category, test.category_blueprint, options: ->(widget) { { dynamic_val: widget.fetch(:id) + 1 } }
    end
    result = blueprint.render({ id: 41, category: { name: 'Foo' } }).to_hash
    expect(result).to eq({ category: { name: 'Foo', val: 42 } })
  end

  it 'applies a Proc to the options (collections)' do
    test = self
    blueprint = Class.new(Blueprinter::V2::Base) do
      extensions { |exts| exts << test.subject }
      association :categories, [test.category_blueprint], options: ->(widget) { { dynamic_val: widget.fetch(:id) + 1 } }
    end
    result = blueprint.render({ id: 41, categories: [{ name: 'Foo' }] }).to_hash
    expect(result).to eq({ categories: [{ name: 'Foo', val: 42 }] })
  end
end
