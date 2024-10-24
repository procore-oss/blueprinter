# frozen_string_literal: true

describe Blueprinter::V2::Serializer do
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

  let(:instance_cache) { Blueprinter::V2::InstanceCache.new }

  it 'should serialize a basic blueprint' do
    test = self
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
      object :category, test.category_blueprint
      collection :parts, test.part_blueprint
    end
    widget = {
      name: 'Foo',
      extra: 'bar',
      category: { name: 'Bar', extra: 'bar' },
      parts: [{ num: 42, extra: 'bar' }]
    }

    result = described_class.new(widget_blueprint).call(widget, {}, instance_cache)
    expect(result).to eq({
      name: 'Foo',
      category: { name: 'Bar' },
      parts: [{ num: 42 }]
    })
  end
end
