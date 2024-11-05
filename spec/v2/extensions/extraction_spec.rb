# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Values do
  include ExtensionHelpers

  let(:object) { { foo: 'Foo', foo_obj: { name: 'Bar' }, foos: [{ num: 42 }] } }
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

  it 'should detect hashes as objects' do
    expect(subject.collection? object).to be false
  end

  it 'should detect arrays as collections' do
    expect(subject.collection? [object]).to be true
  end

  it 'should detect sets as collections' do
    expect(subject.collection? Set.new([object])).to be true
  end

  context 'fields' do
    let(:field) { blueprint.reflections[:default].fields[:foo] }

    it 'should extract a field with the default extractor' do
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'Foo'
    end

    it 'should extract a field with the field options extractor' do
      blueprint.field :foo, extractor: my_extractor
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'FOO'
    end

    it 'should extract a field with the blueprint options extractor' do
      blueprint.options[:extractor] = my_extractor
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'FOO'
    end
  end

  context 'objects' do
    let(:field) { blueprint.reflections[:default].objects[:foo_obj] }

    it 'should extract an object the default extractor' do
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq({ name: 'Bar' })
    end

    it 'should extract an object the field options extractor' do
      blueprint.object :foo_obj, sub_blueprint, extractor: my_extractor
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq({ name: 'BAR' })
    end

    it 'should extract an object the blueprint options extractor' do
      blueprint.options[:extractor] = my_extractor
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq({ name: 'BAR' })
    end
  end

  context 'collections' do
    let(:field) { blueprint.reflections[:default].collections[:foos] }

    it 'should extract an object the default extractor' do
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq [{ num: 42 }]
    end

    it 'should extract an object the field options extractor' do
      blueprint.collection :foos, sub_blueprint, extractor: my_extractor
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq [{ num: 84 }]
    end

    it 'should extract an object the blueprint options extractor' do
      blueprint.options[:extractor] = my_extractor
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq [{ num: 84 }]
    end
  end
end
