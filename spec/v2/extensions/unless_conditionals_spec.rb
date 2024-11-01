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

    it 'should check options field_unless (Proc)' do
      ctx = context.new(blueprint.new, field, :foo, object, { field_unless: ->(ctx) { foo? ctx } })
      expect(subject.exclude_field? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, { field_unless: ->(ctx) { foo? ctx } })
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should check field options unless (Proc)' do
      field.options[:unless] = ->(ctx) { foo? ctx }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_field? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should check blueprint options field_unless (Proc)' do
      blueprint.options[:field_unless] = ->(ctx) { foo? ctx }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_field? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should check options field_unless (Symbol)' do
      ctx = context.new(blueprint.new, field, :foo, object, { field_unless: :foo? })
      expect(subject.exclude_field? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, { field_unless: :foo? })
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should check field options unless (Symbol)' do
      field.options[:unless] = :foo?
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_field? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should check blueprint options field_unless (Symbol)' do
      blueprint.options[:field_unless] = :foo?
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_field? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_field? ctx).to be false
    end
  end

  context 'objects' do
    let(:field) { Blueprinter::V2::ObjectField.new(name: :name, from: :name, options: {}) }

    it 'should be allowed by default' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should check options object_unless (Proc)' do
      ctx = context.new(blueprint.new, field, :foo, object, { object_unless: ->(ctx) { foo? ctx } })
      expect(subject.exclude_object? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, { object_unless: ->(ctx) { foo? ctx } })
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should check field options unless (Proc)' do
      field.options[:unless] = ->(ctx) { foo? ctx }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_object? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should check blueprint options object_unless (Proc)' do
      blueprint.options[:object_unless] = ->(ctx) { foo? ctx }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_object? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should check options object_unless (Symbol)' do
      ctx = context.new(blueprint.new, field, :foo, object, { object_unless: :foo? })
      expect(subject.exclude_object? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, { object_unless: :foo? })
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should check field options unless (Symbol)' do
      field.options[:unless] = :foo?
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_object? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should check blueprint options object_unless (Symbol)' do
      blueprint.options[:object_unless] = :foo?
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_object? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_object? ctx).to be false
    end
  end

  context 'collections' do
    let(:field) { Blueprinter::V2::Collection.new(name: :name, from: :name, options: {}) }

    it 'should be allowed by default' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should check options collection_unless (Proc)' do
      ctx = context.new(blueprint.new, field, :foo, object, { collection_unless: ->(ctx) { foo? ctx } })
      expect(subject.exclude_collection? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, { collection_unless: ->(ctx) { foo? ctx } })
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should check field options unless (Proc)' do
      field.options[:unless] = ->(ctx) { foo? ctx }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_collection? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should check blueprint options collection_unless (Proc)' do
      blueprint.options[:collection_unless] = ->(ctx) { foo? ctx }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_collection? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should check options collection_unless (Symbol)' do
      ctx = context.new(blueprint.new, field, :foo, object, { collection_unless: :foo? })
      expect(subject.exclude_collection? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, { collection_unless: :foo? })
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should check field options unless (Symbol)' do
      field.options[:unless] = :foo?
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_collection? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should check blueprint options collection_unless (Symbol)' do
      blueprint.options[:collection_unless] = :foo?
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_collection? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_collection? ctx).to be false
    end
  end
end
