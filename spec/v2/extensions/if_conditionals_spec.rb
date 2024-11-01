# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Exclusions do
  subject { described_class.new }
  let(:context) { Blueprinter::V2::Context }
  let(:object) { { name: 'Foo' } }
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      def foo?(ctx)
        ctx.value == :foo
      end
    end
  end

  context 'fields' do
    let(:field) { Blueprinter::V2::Field.new(name: :name, from: :name, options: {}) }

    it 'should be allowed by default' do
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should check options field_if (Proc)' do
      ctx = context.new(blueprint.new, field, :foo, object, { field_if: ->(ctx) { foo? ctx } })
      expect(subject.exclude_field? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, { field_if: ->(ctx) { foo? ctx } })
      expect(subject.exclude_field? ctx).to be true
    end

    it 'should check field options if (Proc)' do
      field.options[:if] = ->(ctx) { foo? ctx }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_field? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_field? ctx).to be true
    end

    it 'should check blueprint options field_if (Proc)' do
      blueprint.options[:field_if] = ->(ctx) { foo? ctx }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_field? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_field? ctx).to be true
    end

    it 'should check options field_if (Symbol)' do
      ctx = context.new(blueprint.new, field, :foo, object, { field_if: :foo? })
      expect(subject.exclude_field? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, { field_if: :foo? })
      expect(subject.exclude_field? ctx).to be true
    end

    it 'should check field options if (Symbol)' do
      field.options[:if] = :foo?
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_field? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_field? ctx).to be true
    end

    it 'should check blueprint options field_if (Symbol)' do
      blueprint.options[:field_if] = :foo?
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_field? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_field? ctx).to be true
    end
  end

  context 'objects' do
    let(:field) { Blueprinter::V2::ObjectField.new(name: :name, from: :name, options: {}) }

    it 'should be allowed by default' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should check options object_if (Proc)' do
      ctx = context.new(blueprint.new, field, :foo, object, { object_if: ->(ctx) { foo? ctx } })
      expect(subject.exclude_object? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, { object_if: ->(ctx) { foo? ctx } })
      expect(subject.exclude_object? ctx).to be true
    end

    it 'should check field options if (Proc)' do
      field.options[:if] = ->(ctx) { foo? ctx }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_object? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_object? ctx).to be true
    end

    it 'should check blueprint options object_if (Proc)' do
      blueprint.options[:object_if] = ->(ctx) { foo? ctx }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_object? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_object? ctx).to be true
    end

    it 'should check options object_if (Symbol)' do
      ctx = context.new(blueprint.new, field, :foo, object, { object_if: :foo? })
      expect(subject.exclude_object? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, { object_if: :foo? })
      expect(subject.exclude_object? ctx).to be true
    end

    it 'should check field options if (Symbol)' do
      field.options[:if] = :foo?
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_object? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_object? ctx).to be true
    end

    it 'should check blueprint options object_if (Symbol)' do
      blueprint.options[:object_if] = :foo?
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_object? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_object? ctx).to be true
    end
  end

  context 'collections' do
    let(:field) { Blueprinter::V2::Collection.new(name: :name, from: :name, options: {}) }

    it 'should be allowed by default' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should check options collection_if (Proc)' do
      ctx = context.new(blueprint.new, field, :foo, object, { collection_if: ->(ctx) { foo? ctx } })
      expect(subject.exclude_collection? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, { collection_if: ->(ctx) { foo? ctx } })
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'should check field options if (Proc)' do
      field.options[:if] = ->(ctx) { foo? ctx }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_collection? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'should check blueprint options collection_if (Proc)' do
      blueprint.options[:collection_if] = ->(ctx) { foo? ctx }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_collection? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'should check options collection_if (Symbol)' do
      ctx = context.new(blueprint.new, field, :foo, object, { collection_if: :foo? })
      expect(subject.exclude_collection? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, { collection_if: :foo? })
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'should check field options if (Symbol)' do
      field.options[:if] = :foo?
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_collection? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'should check blueprint options collection_if (Symbol)' do
      blueprint.options[:collection_if] = :foo?
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_collection? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_collection? ctx).to be true
    end
  end
end
