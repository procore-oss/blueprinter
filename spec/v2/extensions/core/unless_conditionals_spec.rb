# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Core::Exclusions do
  include ExtensionHelpers
  let(:object) { { foo: 'Foo' } }

  context 'fields' do
    let(:field) { blueprint.reflections[:default].fields[:foo] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, field, 'Foo', object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'checks options field_unless (Proc)' do
      ctx = prepare(blueprint, field, 'Foo', object, { field_unless: ->(ctx) { foo? ctx } })
      expect(subject.exclude_field? ctx).to be true

      ctx = prepare(blueprint, field, 'Bar', object, { field_unless: ->(ctx) { foo? ctx } })
      expect(subject.exclude_field? ctx).to be false
    end

    it 'checks field options unless (Proc)' do
      blueprint.field :foo, unless: ->(ctx) { foo? ctx }
      ctx = prepare(blueprint, field, 'Foo', object, {})
      expect(subject.exclude_field? ctx).to be true

      ctx = prepare(blueprint, field, 'Bar', object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'checks blueprint options field_unless (Proc)' do
      blueprint.options[:field_unless] = ->(ctx) { foo? ctx }
      ctx = prepare(blueprint, field, 'Foo', object, {})
      expect(subject.exclude_field? ctx).to be true

      ctx = prepare(blueprint, field, 'Bar', object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'checks options field_unless (Symbol)' do
      ctx = prepare(blueprint, field, 'Foo', object, { field_unless: :foo? })
      expect(subject.exclude_field? ctx).to be true

      ctx = prepare(blueprint, field, 'Bar', object, { field_unless: :foo? })
      expect(subject.exclude_field? ctx).to be false
    end

    it 'checks field options unless (Symbol)' do
      blueprint.field :foo, unless: :foo?
      ctx = prepare(blueprint, field, 'Foo', object, {})
      expect(subject.exclude_field? ctx).to be true

      ctx = prepare(blueprint, field, 'Bar', object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'checks blueprint options field_unless (Symbol)' do
      blueprint.options[:field_unless] = :foo?
      ctx = prepare(blueprint, field, 'Foo', object, {})
      expect(subject.exclude_field? ctx).to be true

      ctx = prepare(blueprint, field, 'Bar', object, {})
      expect(subject.exclude_field? ctx).to be false
    end
  end

  context 'objects' do
    let(:field) { blueprint.reflections[:default].objects[:foo_obj] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, field, { name: 'Foo' }, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'checks options object_unless (Proc)' do
      ctx = prepare(blueprint, field, { name: 'Foo' }, object, { object_unless: ->(ctx) { name_foo? ctx } })
      expect(subject.exclude_object? ctx).to be true

      ctx = prepare(blueprint, field, { name: 'Bar' }, object, { object_unless: ->(ctx) { name_foo? ctx } })
      expect(subject.exclude_object? ctx).to be false
    end

    it 'checks field options unless (Proc)' do
      blueprint.object :foo_obj, sub_blueprint, unless: ->(ctx) { name_foo? ctx }
      ctx = prepare(blueprint, field, { name: 'Foo' }, object, {})
      expect(subject.exclude_object? ctx).to be true

      ctx = prepare(blueprint, field, { name: 'Bar' }, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'checks blueprint options object_unless (Proc)' do
      blueprint.options[:object_unless] = ->(ctx) { name_foo? ctx }
      ctx = prepare(blueprint, field, { name: 'Foo' }, object, {})
      expect(subject.exclude_object? ctx).to be true

      ctx = prepare(blueprint, field, { name: 'Bar' }, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'checks options object_unless (Symbol)' do
      ctx = prepare(blueprint, field, { name: 'Foo' }, object, { object_unless: :name_foo? })
      expect(subject.exclude_object? ctx).to be true

      ctx = prepare(blueprint, field, { name: 'Bar' }, object, { object_unless: :name_foo? })
      expect(subject.exclude_object? ctx).to be false
    end

    it 'checks field options unless (Symbol)' do
      blueprint.object :foo_obj, sub_blueprint, unless: :name_foo?
      ctx = prepare(blueprint, field, { name: 'Foo' }, object, {})
      expect(subject.exclude_object? ctx).to be true

      ctx = prepare(blueprint, field, { name: 'Bar' }, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'checks blueprint options object_unless (Symbol)' do
      blueprint.options[:object_unless] = :name_foo?
      ctx = prepare(blueprint, field, { name: 'Foo' }, object, {})
      expect(subject.exclude_object? ctx).to be true

      ctx = prepare(blueprint, field, { name: 'Bar' }, object, {})
      expect(subject.exclude_object? ctx).to be false
    end
  end

  context 'collections' do
    let(:field) { blueprint.reflections[:default].collections[:foos] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, field, [{ name: 'Foo' }], object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'checks options collection_unless (Proc)' do
      ctx = prepare(blueprint, field, [{ name: 'Foo' }], object, { collection_unless: ->(ctx) { names_foo? ctx } })
      expect(subject.exclude_collection? ctx).to be true

      ctx = prepare(blueprint, field, [{ name: 'Bar' }], object, { collection_unless: ->(ctx) { names_foo? ctx } })
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'checks field options unless (Proc)' do
      blueprint.collection :foos, sub_blueprint, unless: ->(ctx) { names_foo? ctx }
      ctx = prepare(blueprint, field, [{ name: 'Foo' }], object, {})
      expect(subject.exclude_collection? ctx).to be true

      ctx = prepare(blueprint, field, [{ name: 'Bar' }], object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'checks blueprint options collection_unless (Proc)' do
      blueprint.options[:collection_unless] = ->(ctx) { names_foo? ctx }
      ctx = prepare(blueprint, field, [{ name: 'Foo' }], object, {})
      expect(subject.exclude_collection? ctx).to be true

      ctx = prepare(blueprint, field, [{ name: 'Bar' }], object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'checks options collection_unless (Symbol)' do
      ctx = prepare(blueprint, field, [{ name: 'Foo' }], object, { collection_unless: :names_foo? })
      expect(subject.exclude_collection? ctx).to be true

      ctx = prepare(blueprint, field, [{ name: 'Bar' }], object, { collection_unless: :names_foo? })
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'checks field options unless (Symbol)' do
      blueprint.collection :foos, sub_blueprint, unless: :names_foo?
      ctx = prepare(blueprint, field, [{ name: 'Foo' }], object, {})
      expect(subject.exclude_collection? ctx).to be true

      ctx = prepare(blueprint, field, [{ name: 'Bar' }], object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'checks blueprint options collection_unless (Symbol)' do
      blueprint.options[:collection_unless] = :names_foo?
      ctx = prepare(blueprint, field, [{ name: 'Foo' }], object, {})
      expect(subject.exclude_collection? ctx).to be true

      ctx = prepare(blueprint, field, [{ name: 'Bar' }], object, {})
      expect(subject.exclude_collection? ctx).to be false
    end
  end
end
