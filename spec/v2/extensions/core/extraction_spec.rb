# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Core::Values do
  include ExtensionHelpers

  let(:object) { { foo: 'Foo', foo_obj: { name: 'Bar' }, foos: [{ num: 42 }] } }
  let(:my_extractor) do
    Class.new(Blueprinter::Extractor) do
      def field(ctx)
        ctx.object[ctx.field.from].upcase
      end

      def object(ctx)
        val = ctx.object[ctx.field.from]
        val.transform_values { |v| v.upcase }
      end

      def collection(ctx)
        vals = ctx.object[ctx.field.from]
        vals.map { |val| val.transform_values { |v| v * 2 } }
      end
    end
  end

  context 'fields' do
    let(:field) { blueprint.reflections[:default].fields[:foo] }

    it 'extracts a value using the default extractor' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.field_value ctx).to eq 'Foo'
    end

    it 'extracts a value using a block' do
      field = blueprint.reflections[:default].fields[:foo2]
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.field_value ctx).to eq 'value: Foo'
    end

    it 'extracts a value using the field options extractor' do
      blueprint.field :foo, extractor: my_extractor
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.field_value ctx).to eq 'FOO'
    end

    it 'extracts a value using the blueprint options extractor' do
      blueprint.options[:extractor] = my_extractor
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.field_value ctx).to eq 'FOO'
    end
  end

  context 'objects' do
    let(:field) { blueprint.reflections[:default].objects[:foo_obj] }

    it 'extracts a value using the default extractor' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.object_value ctx).to eq({ name: 'Bar' })
    end

    it 'extracts a value using a block' do
      field = blueprint.reflections[:default].objects[:foo_obj2]
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.field_value ctx).to eq({ name: 'name: Bar' })
    end

    it 'extracts a value using the field options extractor' do
      blueprint.object :foo_obj, sub_blueprint, extractor: my_extractor
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.object_value ctx).to eq({ name: 'BAR' })
    end

    it 'extracts a value using the blueprint options extractor' do
      blueprint.options[:extractor] = my_extractor
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.object_value ctx).to eq({ name: 'BAR' })
    end
  end

  context 'collections' do
    let(:field) { blueprint.reflections[:default].collections[:foos] }

    it 'extracts a value using the default extractor' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.collection_value ctx).to eq [{ num: 42 }]
    end

    it 'extracts a field using a block' do
      field = blueprint.reflections[:default].collections[:foos2]
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.field_value ctx).to eq([{ name: 'nums: 42' }])
    end

    it 'extracts a value using the field options extractor' do
      blueprint.collection :foos, sub_blueprint, extractor: my_extractor
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.collection_value ctx).to eq [{ num: 84 }]
    end

    it 'extracts a value using the blueprint options extractor' do
      blueprint.options[:extractor] = my_extractor
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.collection_value ctx).to eq [{ num: 84 }]
    end
  end
end
