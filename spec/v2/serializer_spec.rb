# frozen_string_literal: true

require 'date'
require 'json'

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

  let(:widget_blueprint) do
    test = self
    Class.new(Blueprinter::V2::Base) do
      field :name
      object :category, test.category_blueprint
      collection :parts, test.part_blueprint
    end
  end

  let(:instance_cache) { Blueprinter::V2::InstanceCache.new }

  it 'should work with nil values' do
    test = self
    widget = { name: nil, category: nil }

    result = described_class.new(widget_blueprint).call(widget, {}, instance_cache)
    expect(result).to eq({
      name: nil,
      category: nil,
      parts: nil
    })
  end

  it 'should extract values and serialize nested Blueprints' do
    test = self
    widget = {
      name: 'Foo',
      extra: 'bar',
      category: { name: 'Bar', extra: 'bar' },
      parts: [{ num: 42, extra: 'bar' }, { num: 43 }]
    }

    result = described_class.new(widget_blueprint).call(widget, {}, instance_cache)
    expect(result).to eq({
      name: 'Foo',
      category: { name: 'Bar' },
      parts: [{ num: 42 }, { num: 43 }]
    })
  end

  it 'should enable the default values extension' do
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
      field :desc, default: 'Description!'
    end

    result = described_class.new(widget_blueprint).call({ name: 'Foo' }, {}, instance_cache)
    expect(result).to eq({
      name: 'Foo',
      desc: 'Description!'
    })
  end

  it 'should format fields' do
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      format(Date) { |date| date.strftime('%a %b %e, %Y') }
      field :name
      field :created_on
    end
    widget = { name: 'Foo', created_on: Date.new(2024, 10, 31) }

    result = described_class.new(widget_blueprint).call(widget, {}, instance_cache)
    expect(result).to eq({
      name: 'Foo',
      created_on: 'Thu Oct 31, 2024'
    })
  end

  it 'should run blueprint_input hooks before anything else' do
    ext = Class.new(Blueprinter::Extension) do
      def blueprint_input(_ctx)
        { name: 'Foo' }
      end
    end
    widget_blueprint.extensions << ext.new

    result = described_class.new(widget_blueprint).call(
      { category: { name: 'Cat' }, parts: [{ num: 42 }] },
      {},
      instance_cache
    )
    expect(result).to eq({ name: 'Foo', category: nil, parts: nil })
  end

  it 'should run blueprint_output hooks after everything else' do
    ext = Class.new(Blueprinter::Extension) do
      def blueprint_output(_ctx)
        { name: 'Foo' }
      end
    end
    widget_blueprint.extensions << ext.new

    result = described_class.new(widget_blueprint).call(
      { category: { name: 'Cat' }, parts: [{ num: 42 }] },
      {},
      instance_cache
    )
    expect(result).to eq({ name: 'Foo' })
  end

  it 'should put fields in the order they were defined' do
    blueprint = Class.new(widget_blueprint) do
      field :description
    end

    result = described_class.new(blueprint).call(
      { description: 'A widget', category: { name: 'Cat' }, parts: [{ num: 42 }], name: 'Foo' },
      {},
      instance_cache
    )
    expect(result.to_json).to eq({
      name: 'Foo',
      category: { name: 'Cat' },
      parts: [{ num: 42 }],
      description: 'A widget'
      }.to_json)
  end

  context 'V1 child Blueprints' do
    it 'should serialize objects'

    it 'should be nil if the object is nil'

    it 'should serialize collections'

    it 'should be nil if the collection is nil'

    it 'should be an empty array if the collection is empty'
  end
end
