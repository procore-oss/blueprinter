# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Extraction do
  subject { described_class.new }
  let(:instance_cache) { Blueprinter::V2::InstanceCache.new }
  let(:context) { Blueprinter::V2::Serializer::Context }
  let(:blueprint) { Class.new(Blueprinter::V2::Base) }
  let(:object) { { name: 'Foo', category: { name: 'Bar' }, parts: [{ num: 42 }] } }
  let(:my_extractor) do
    Class.new(Blueprinter::V2::Extractor) do
      def field(_blueprint, field, obj, _options)
        obj[field.from].upcase
      end

      def object(_blueprint, field, obj, _options)
        val = obj[field.from]
        val.transform_values { |v| v.upcase }
      end

      def collection(_blueprint, field, obj, _options)
        vals = obj[field.from]
        vals.map { |val| val.transform_values { |v| v * 2 } }
      end
    end
  end

  context 'fields' do
    let(:field) { Blueprinter::V2::Field.new(name: :name, from: :name, options: {}) }

    it 'should extract a field with the default extractor' do
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'Foo'
    end

    it 'should extract a field with the field options extractor' do
      field.options[:extractor] = my_extractor
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'FOO'
    end

    it 'should extract a field with the blueprint options extractor' do
      blueprint.options[:extractor] = my_extractor
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'FOO'
    end
  end

  context 'objects' do
    let(:field) { Blueprinter::V2::Association.new(name: :category, from: :category, collection: false, options: {}) }

    it 'should extract an object the default extractor' do
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.object_value ctx).to eq({ name: 'Bar' })
    end

    it 'should extract an object the field options extractor' do
      field.options[:extractor] = my_extractor
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.object_value ctx).to eq({ name: 'BAR' })
    end

    it 'should extract an object the blueprint options extractor' do
      blueprint.options[:extractor] = my_extractor
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.object_value ctx).to eq({ name: 'BAR' })
    end
  end

  context 'collections' do
    let(:field) { Blueprinter::V2::Association.new(name: :parts, from: :parts, collection: true, options: {}) }

    it 'should extract an object the default extractor' do
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq [{ num: 42 }]
    end

    it 'should extract an object the field options extractor' do
      field.options[:extractor] = my_extractor
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq [{ num: 84 }]
    end

    it 'should extract an object the blueprint options extractor' do
      blueprint.options[:extractor] = my_extractor
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq [{ num: 84 }]
    end
  end
end
