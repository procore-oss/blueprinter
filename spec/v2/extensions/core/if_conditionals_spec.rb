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

    it 'checks options field_if (Proc)' do
      ctx = prepare(blueprint, { field_if: ->(ctx) { foo? ctx } }, Blueprinter::V2::Context::Field, object, field, 'Foo')
      expect(subject.exclude_field? ctx).to be false

      ctx = prepare(blueprint, { field_if: ->(ctx) { foo? ctx } }, Blueprinter::V2::Context::Field, object, field, 'Bar')
      expect(subject.exclude_field? ctx).to be true
    end

    it 'checks field options if (Proc)' do
      blueprint.field :foo, if: ->(ctx) { foo? ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Foo')
      expect(subject.exclude_field? ctx).to be false

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Bar')
      expect(subject.exclude_field? ctx).to be true
    end

    it 'checks blueprint options field_if (Proc)' do
      blueprint.options[:field_if] = ->(ctx) { foo? ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Foo')
      expect(subject.exclude_field? ctx).to be false

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Bar')
      expect(subject.exclude_field? ctx).to be true
    end

    it 'checks options field_if (Symbol)' do
      ctx = prepare(blueprint, { field_if: :foo? }, Blueprinter::V2::Context::Field, object, field, 'Foo')
      expect(subject.exclude_field? ctx).to be false

      ctx = prepare(blueprint, { field_if: :foo? }, Blueprinter::V2::Context::Field, object, field, 'Bar')
      expect(subject.exclude_field? ctx).to be true
    end

    it 'checks field options if (Symbol)' do
      blueprint.field :foo, if: :foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Foo')
      expect(subject.exclude_field? ctx).to be false

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Bar')
      expect(subject.exclude_field? ctx).to be true
    end

    it 'checks blueprint options field_if (Symbol)' do
      blueprint.options[:field_if] = :foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Foo')
      expect(subject.exclude_field? ctx).to be false

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Bar')
      expect(subject.exclude_field? ctx).to be true
    end
  end

  context 'objects' do
    let(:field) { blueprint.reflections[:default].objects[:foo_obj] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object_field? ctx).to be false
    end

    it 'checks options object_if (Proc)' do
      ctx = prepare(blueprint, { object_if: ->(ctx) { name_foo? ctx } }, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object_field? ctx).to be false

      ctx = prepare(blueprint, { object_if: ->(ctx) { name_foo? ctx } }, Blueprinter::V2::Context::Field, object, field, { name: 'Bar' })
      expect(subject.exclude_object_field? ctx).to be true
    end

    it 'checks field options if (Proc)' do
      blueprint.object :foo_obj, sub_blueprint, if: ->(ctx) { name_foo? ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object_field? ctx).to be false

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Bar' })
      expect(subject.exclude_object_field? ctx).to be true
    end

    it 'checks blueprint options object_if (Proc)' do
      blueprint.options[:object_if] = ->(ctx) { name_foo? ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object_field? ctx).to be false

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Bar' })
      expect(subject.exclude_object_field? ctx).to be true
    end

    it 'checks options object_if (Symbol)' do
      ctx = prepare(blueprint, { object_if: :name_foo? }, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object_field? ctx).to be false

      ctx = prepare(blueprint, { object_if: :name_foo? }, Blueprinter::V2::Context::Field, object, field, { name: 'Bar' })
      expect(subject.exclude_object_field? ctx).to be true
    end

    it 'checks field options if (Symbol)' do
      blueprint.object :foo_obj, sub_blueprint, if: :name_foo?
      ctx = prepare(blueprint, { object_if: :name_foo? }, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object_field? ctx).to be false

      ctx = prepare(blueprint, { object_if: :name_foo? }, Blueprinter::V2::Context::Field, object, field, { name: 'Bar' })
      expect(subject.exclude_object_field? ctx).to be true
    end

    it 'checks blueprint options object_if (Symbol)' do
      blueprint.options[:object_if] = :name_foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object_field? ctx).to be false

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Bar' })
      expect(subject.exclude_object_field? ctx).to be true
    end
  end

  context 'collections' do
    let(:field) { blueprint.reflections[:default].collections[:foos] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection_field? ctx).to be false
    end

    it 'checks options collection_if (Proc)' do
      ctx = prepare(blueprint, { collection_if: ->(ctx) { names_foo? ctx } }, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection_field? ctx).to be false

      ctx = prepare(blueprint, { collection_if: ->(ctx) { names_foo? ctx } }, Blueprinter::V2::Context::Field, object, field, [{ name: 'Bar' }])
      expect(subject.exclude_collection_field? ctx).to be true
    end

    it 'checks field options if (Proc)' do
      blueprint.collection :foos, sub_blueprint, if: ->(ctx) { names_foo? ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection_field? ctx).to be false

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Bar' }])
      expect(subject.exclude_collection_field? ctx).to be true
    end

    it 'checks blueprint options collection_if (Proc)' do
      blueprint.options[:collection_if] = ->(ctx) { names_foo? ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection_field? ctx).to be false

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Bar' }])
      expect(subject.exclude_collection_field? ctx).to be true
    end

    it 'checks options collection_if (Symbol)' do
      ctx = prepare(blueprint, { collection_if: :names_foo? }, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection_field? ctx).to be false

      ctx = prepare(blueprint, { collection_if: :names_foo? }, Blueprinter::V2::Context::Field, object, field, [{ name: 'Bar' }])
      expect(subject.exclude_collection_field? ctx).to be true
    end

    it 'checks field options if (Symbol)' do
      blueprint.collection :foos, sub_blueprint, if: :names_foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection_field? ctx).to be false

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Bar' }])
      expect(subject.exclude_collection_field? ctx).to be true
    end

    it 'checks blueprint options collection_if (Symbol)' do
      blueprint.options[:collection_if] = :names_foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection_field? ctx).to be false

      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Bar' }])
      expect(subject.exclude_collection_field? ctx).to be true
    end
  end
end
