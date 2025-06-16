# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Core::Conditionals do
  include ExtensionHelpers
  let(:object) { { foo: 'Foo' } }

  context 'fields' do
    let(:field) { blueprint.reflections[:default].fields[:foo] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Foo')
      expect(subject.exclude_field? ctx).to be false
    end

    it 'checks options field_unless (Proc)' do
      ctx = prepare(blueprint, { field_unless: ->(ctx) { foo? ctx } }, Blueprinter::V2::Context::Field, object, field, 'Foo')
      expect(subject.exclude_field? ctx).to be true

      ctx = prepare(blueprint, { field_unless: ->(ctx) { foo? ctx } }, Blueprinter::V2::Context::Field, object, field, 'Bar')
      expect(subject.exclude_field? ctx).to be false
    end

    it 'checks field options unless (Proc)' do
      blueprint.field :foo, unless: ->(ctx) { foo? ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Foo')
      expect(subject.exclude_field? ctx).to be true

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Bar')
      expect(subject.exclude_field? ctx).to be false
    end

    it 'checks blueprint options field_unless (Proc)' do
      blueprint.options[:field_unless] = ->(ctx) { foo? ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Foo')
      expect(subject.exclude_field? ctx).to be true

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Bar')
      expect(subject.exclude_field? ctx).to be false
    end

    it 'checks options field_unless (Symbol)' do
      ctx = prepare(blueprint, { field_unless: :foo? }, Blueprinter::V2::Context::Field, object, field, 'Foo')
      expect(subject.exclude_field? ctx).to be true

      ctx = prepare(blueprint, { field_unless: :foo? }, Blueprinter::V2::Context::Field, object, field, 'Bar')
      expect(subject.exclude_field? ctx).to be false
    end

    it 'checks field options unless (Symbol)' do
      blueprint.field :foo, unless: :foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Foo')
      expect(subject.exclude_field? ctx).to be true

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Bar')
      expect(subject.exclude_field? ctx).to be false
    end

    it 'checks blueprint options field_unless (Symbol)' do
      blueprint.options[:field_unless] = :foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Foo')
      expect(subject.exclude_field? ctx).to be true

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Bar')
      expect(subject.exclude_field? ctx).to be false
    end
  end

  context 'objects' do
    let(:field) { blueprint.reflections[:default].objects[:foo_obj] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object_field? ctx).to be false
    end

    it 'checks options object_unless (Proc)' do
      ctx = prepare(blueprint, { object_unless: ->(ctx) { name_foo? ctx } }, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object_field? ctx).to be true

      ctx = prepare(blueprint, { object_unless: ->(ctx) { name_foo? ctx } }, Blueprinter::V2::Context::Field, object, field, { name: 'Bar' })
      expect(subject.exclude_object_field? ctx).to be false
    end

    it 'checks field options unless (Proc)' do
      blueprint.object :foo_obj, sub_blueprint, unless: ->(ctx) { name_foo? ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object_field? ctx).to be true

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Bar' })
      expect(subject.exclude_object_field? ctx).to be false
    end

    it 'checks blueprint options object_unless (Proc)' do
      blueprint.options[:object_unless] = ->(ctx) { name_foo? ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object_field? ctx).to be true

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Bar' })
      expect(subject.exclude_object_field? ctx).to be false
    end

    it 'checks options object_unless (Symbol)' do
      ctx = prepare(blueprint, { object_unless: :name_foo? }, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object_field? ctx).to be true

      ctx = prepare(blueprint, { object_unless: :name_foo? }, Blueprinter::V2::Context::Field, object, field, { name: 'Bar' })
      expect(subject.exclude_object_field? ctx).to be false
    end

    it 'checks field options unless (Symbol)' do
      blueprint.object :foo_obj, sub_blueprint, unless: :name_foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object_field? ctx).to be true

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Bar' })
      expect(subject.exclude_object_field? ctx).to be false
    end

    it 'checks blueprint options object_unless (Symbol)' do
      blueprint.options[:object_unless] = :name_foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object_field? ctx).to be true

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Bar' })
      expect(subject.exclude_object_field? ctx).to be false
    end
  end

  context 'collections' do
    let(:field) { blueprint.reflections[:default].collections[:foos] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection_field? ctx).to be false
    end

    it 'checks options collection_unless (Proc)' do
      ctx = prepare(blueprint, { collection_unless: ->(ctx) { names_foo? ctx } }, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection_field? ctx).to be true

      ctx = prepare(blueprint, { collection_unless: ->(ctx) { names_foo? ctx } }, Blueprinter::V2::Context::Field, object, field, [{ name: 'Bar' }])
      expect(subject.exclude_collection_field? ctx).to be false
    end

    it 'checks field options unless (Proc)' do
      blueprint.collection :foos, sub_blueprint, unless: ->(ctx) { names_foo? ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection_field? ctx).to be true

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Bar' }])
      expect(subject.exclude_collection_field? ctx).to be false
    end

    it 'checks blueprint options collection_unless (Proc)' do
      blueprint.options[:collection_unless] = ->(ctx) { names_foo? ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection_field? ctx).to be true

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Bar' }])
      expect(subject.exclude_collection_field? ctx).to be false
    end

    it 'checks options collection_unless (Symbol)' do
      ctx = prepare(blueprint, { collection_unless: :names_foo? }, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection_field? ctx).to be true

      ctx = prepare(blueprint, { collection_unless: :names_foo? }, Blueprinter::V2::Context::Field, object, field, [{ name: 'Bar' }])
      expect(subject.exclude_collection_field? ctx).to be false
    end

    it 'checks field options unless (Symbol)' do
      blueprint.collection :foos, sub_blueprint, unless: :names_foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection_field? ctx).to be true

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Bar' }])
      expect(subject.exclude_collection_field? ctx).to be false
    end

    it 'checks blueprint options collection_unless (Symbol)' do
      blueprint.options[:collection_unless] = :names_foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection_field? ctx).to be true

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Bar' }])
      expect(subject.exclude_collection_field? ctx).to be false
    end
  end
end
