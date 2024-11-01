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

    it 'are allowed by default if nil' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.exclude_field? ctx).to be false
    end

    it 'are allowed with options set' do
      ctx = prepare(blueprint, { exclude_if_empty: true }, Blueprinter::V2::Context::Field, object, field, 'Foo')
      expect(subject.exclude_field? ctx).to be false
    end

    it 'are excluded with options set if nil' do
      ctx = prepare(blueprint, { exclude_if_empty: true }, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.exclude_field? ctx).to be true
    end

    it 'are excluded with options set if empty' do
      ctx = prepare(blueprint, { exclude_if_empty: true }, Blueprinter::V2::Context::Field, object, field, [])
      expect(subject.exclude_field? ctx).to be true
    end

    it 'are allowed with field options set' do
      blueprint.field :foo, exclude_if_empty: true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Foo')
      expect(subject.exclude_field? ctx).to be false
    end

    it 'are excluded with field options set if nil' do
      blueprint.field :foo, exclude_if_empty: true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.exclude_field? ctx).to be true
    end

    it 'are excluded with field options set if empty' do
      blueprint.field :foo, exclude_if_empty: true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [])
      expect(subject.exclude_field? ctx).to be true
    end

    it 'are allowed with blueprint options set' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, 'Foo')
      expect(subject.exclude_field? ctx).to be false
    end

    it 'are excluded with blueprint options set if nil' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.exclude_field? ctx).to be true
    end

    it 'are excluded with blueprint options set if empty' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [])
      expect(subject.exclude_field? ctx).to be true
    end
  end

  context 'objects' do
    let(:field) { blueprint.reflections[:default].objects[:foo_obj] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object? ctx).to be false
    end

    it 'are allowed by default if nil' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.exclude_object? ctx).to be false
    end

    it 'are allowed with options set' do
      ctx = prepare(blueprint, { exclude_if_empty: true }, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object? ctx).to be false
    end

    it 'are excluded with options set if nil' do
      ctx = prepare(blueprint, { exclude_if_empty: true }, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.exclude_object? ctx).to be true
    end

    it 'are excluded with options set if empty' do
      ctx = prepare(blueprint, { exclude_if_empty: true }, Blueprinter::V2::Context::Field, object, field, {})
      expect(subject.exclude_object? ctx).to be true
    end

    it 'are allowed with field options set' do
      blueprint.object :foo_obj, sub_blueprint, exclude_if_empty: true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object? ctx).to be false
    end

    it 'are excluded with field options set if nil' do
      blueprint.object :foo_obj, sub_blueprint, exclude_if_empty: true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.exclude_object? ctx).to be true
    end

    it 'are excluded with field options set if empty' do
      blueprint.object :foo_obj, sub_blueprint, exclude_if_empty: true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, {})
      expect(subject.exclude_object? ctx).to be true
    end

    it 'are allowed with blueprint options set' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, { name: 'Foo' })
      expect(subject.exclude_object? ctx).to be false
    end

    it 'are excluded with blueprint options set if nil' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.exclude_object? ctx).to be true
    end

    it 'are excluded with blueprint options set if empty' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, {})
      expect(subject.exclude_object? ctx).to be true
    end
  end

  context 'collections' do
    let(:field) { blueprint.reflections[:default].collections[:foos] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'are allowed by default if nil' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'are allowed with options set' do
      ctx = prepare(blueprint, { exclude_if_empty: true }, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'are excluded with options set if nil' do
      ctx = prepare(blueprint, { exclude_if_empty: true }, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'are excluded with options set if empty' do
      ctx = prepare(blueprint, { exclude_if_empty: true }, Blueprinter::V2::Context::Field, object, field, [])
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'are allowed with field options set' do
      blueprint.collection :foos, sub_blueprint, exclude_if_empty: true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'are excluded with field options set if nil' do
      blueprint.collection :foos, sub_blueprint, exclude_if_empty: true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'are excluded with field options set if empty' do
      blueprint.collection :foos, sub_blueprint, exclude_if_empty: true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [])
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'are allowed with blueprint options set' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [{ name: 'Foo' }])
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'are excluded with blueprint options set if nil' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'are excluded with blueprint options set if empty' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, [])
      expect(subject.exclude_collection? ctx).to be true
    end
  end
end
