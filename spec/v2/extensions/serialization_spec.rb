# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Serialization do
  subject { described_class.new }
  let(:instance_cache) { Blueprinter::V2::InstanceCache.new }
  let(:context) { Blueprinter::V2::Serializer::Context }
  let(:blueprint) { Class.new(Blueprinter::V2::Base) }
  let(:widget_blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :name
      field :description do |_ctx|
        'The description'
      end
    end
  end

  context 'V2 Blueprint' do
    it 'should serialize objects' do
      val = { name: 'Foo' }
      field = Blueprinter::V2::Association.new(name: :widget, from: :widget, blueprint: widget_blueprint, collection: false, options: {})
      ctx = context.new(blueprint.new, field, val, {}, {}, instance_cache)
      expect(subject.object_value ctx).to eq({ name: 'Foo', description: 'The description' })
    end

    it 'should serialize collections' do
      val = [{ name: 'Foo' }, { name: 'Bar' }]
      field = Blueprinter::V2::Association.new(name: :widget, from: :widget, blueprint: widget_blueprint, collection: true, options: {})
      ctx = context.new(blueprint.new, field, val, {}, {}, instance_cache)
      expect(subject.collection_value ctx).to eq([
        { name: 'Foo', description: 'The description' },
        { name: 'Bar', description: 'The description' },
      ])
    end
  end

  context 'V1 Blueprint' do
    it 'should serialize objects'

    it 'should serialize collections'
  end
end
