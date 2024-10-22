# frozen_string_literal: true

describe Blueprinter::V2::Extensions::ConditionalFields do
  subject { described_class.new }
  let(:context) { Blueprinter::V2::Serializer::Context }
  let(:object) { { name: 'Foo' } }
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      def foo?(val)
        val == :foo
      end
    end
  end

  context 'fields' do
    let(:field) { Blueprinter::V2::Field.new(name: :name, from: :name, options: {}) }

    it 'should be allowed by default' do
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should check options field_if' do
      ctx = context.new(blueprint.new, field, :foo, object, { field_if: ->(ctx) { foo? ctx.value } })
      expect(subject.exclude_field? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, { field_if: ->(ctx) { foo? ctx.value } })
      expect(subject.exclude_field? ctx).to be true
    end

    it 'should check field options if' do
      field.options[:if] = ->(ctx) { foo? ctx.value }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_field? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_field? ctx).to be true
    end

    it 'should check blueprint options field_if' do
      blueprint.options[:field_if] = ->(ctx) { foo? ctx.value }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_field? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_field? ctx).to be true
    end

    it 'should check options field_unless' do
      ctx = context.new(blueprint.new, field, :foo, object, { field_unless: ->(ctx) { foo? ctx.value } })
      expect(subject.exclude_field? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, { field_unless: ->(ctx) { foo? ctx.value } })
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should check field options unless' do
      field.options[:unless] = ->(ctx) { foo? ctx.value }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_field? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should check blueprint options field_unless' do
      blueprint.options[:field_unless] = ->(ctx) { foo? ctx.value }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_field? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_field? ctx).to be false
    end
  end

  context 'objects' do
    let(:field) { Blueprinter::V2::Association.new(name: :name, from: :name, collection: false, options: {}) }

    it 'should be allowed by default' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should check options object_if' do
      ctx = context.new(blueprint.new, field, :foo, object, { object_if: ->(ctx) { foo? ctx.value } })
      expect(subject.exclude_object? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, { object_if: ->(ctx) { foo? ctx.value } })
      expect(subject.exclude_object? ctx).to be true
    end

    it 'should check field options if' do
      field.options[:if] = ->(ctx) { foo? ctx.value }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_object? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_object? ctx).to be true
    end

    it 'should check blueprint options object_if' do
      blueprint.options[:object_if] = ->(ctx) { foo? ctx.value }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_object? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_object? ctx).to be true
    end

    it 'should check options object_unless' do
      ctx = context.new(blueprint.new, field, :foo, object, { object_unless: ->(ctx) { foo? ctx.value } })
      expect(subject.exclude_object? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, { object_unless: ->(ctx) { foo? ctx.value } })
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should check field options unless' do
      field.options[:unless] = ->(ctx) { foo? ctx.value }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_object? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should check blueprint options object_unless' do
      blueprint.options[:object_unless] = ->(ctx) { foo? ctx.value }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_object? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_object? ctx).to be false
    end
  end

  context 'collections' do
    let(:field) { Blueprinter::V2::Association.new(name: :name, from: :name, collection: true, options: {}) }

    it 'should be allowed by default' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should be allowed by default' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should check options collection_if' do
      ctx = context.new(blueprint.new, field, :foo, object, { collection_if: ->(ctx) { foo? ctx.value } })
      expect(subject.exclude_collection? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, { collection_if: ->(ctx) { foo? ctx.value } })
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'should check field options if' do
      field.options[:if] = ->(ctx) { foo? ctx.value }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_collection? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'should check blueprint options collection_if' do
      blueprint.options[:collection_if] = ->(ctx) { foo? ctx.value }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_collection? ctx).to be false

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'should check options collection_unless' do
      ctx = context.new(blueprint.new, field, :foo, object, { collection_unless: ->(ctx) { foo? ctx.value } })
      expect(subject.exclude_collection? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, { collection_unless: ->(ctx) { foo? ctx.value } })
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should check field options unless' do
      field.options[:unless] = ->(ctx) { foo? ctx.value }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_collection? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should check blueprint options collection_unless' do
      blueprint.options[:collection_unless] = ->(ctx) { foo? ctx.value }
      ctx = context.new(blueprint.new, field, :foo, object, {})
      expect(subject.exclude_collection? ctx).to be true

      ctx = context.new(blueprint.new, field, :bar, object, {})
      expect(subject.exclude_collection? ctx).to be false
    end
  end
end
