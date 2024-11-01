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

    it 'are allowed by default if nil' do
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'are allowed with options set' do
      ctx = prepare(blueprint, field, 'Foo', object, { exclude_if_nil: true })
      expect(subject.exclude_field? ctx).to be false
    end

    it 'are excluded with options set if nil' do
      ctx = prepare(blueprint, field, nil, object, { exclude_if_nil: true })
      expect(subject.exclude_field? ctx).to be true
    end

    it 'are allowed with field options set' do
      blueprint.field :foo, exclude_if_nil: true
      ctx = prepare(blueprint, field, 'Foo', object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'are excluded with field options set if nil' do
      blueprint.field :foo, exclude_if_nil: true
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_field? ctx).to be true
    end

    it 'are allowed with blueprint options set' do
      blueprint.options[:exclude_if_nil] = true
      ctx = prepare(blueprint, field, 'Foo', object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'are excluded with blueprint options set if nil' do
      blueprint.options[:exclude_if_nil] = true
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_field? ctx).to be true
    end
  end

  context 'objects' do
    let(:field) { blueprint.reflections[:default].objects[:foo_obj] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, field, { name: 'Foo' }, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'are allowed by default if nil' do
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'are allowed with options set' do
      ctx = prepare(blueprint, field, { name: 'Foo' }, object, { exclude_if_nil: true })
      expect(subject.exclude_object? ctx).to be false
    end

    it 'are excluded with options set if nil' do
      ctx = prepare(blueprint, field, nil, object, { exclude_if_nil: true })
      expect(subject.exclude_object? ctx).to be true
    end

    it 'are allowed with field options set' do
      blueprint.object :foo_obj, sub_blueprint, exclude_if_nil: true
      ctx = prepare(blueprint, field, { name: 'Foo' }, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'are excluded with field options set if nil' do
      blueprint.object :foo_obj, sub_blueprint, exclude_if_nil: true
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_object? ctx).to be true
    end

    it 'are allowed with blueprint options set' do
      blueprint.options[:exclude_if_nil] = true
      ctx = prepare(blueprint, field, { name: 'Foo' }, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'are excluded with blueprint options set if nil' do
      blueprint.options[:exclude_if_nil] = true
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_object? ctx).to be true
    end
  end

  context 'collections' do
    let(:field) { blueprint.reflections[:default].collections[:foos] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, field, [{ name: 'Foo' }], object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'are allowed by default if nil' do
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'are allowed with options set' do
      ctx = prepare(blueprint, field, [{ name: 'Foo' }], object, { exclude_if_nil: true })
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'are excluded with options set if nil' do
      ctx = prepare(blueprint, field, nil, object, { exclude_if_nil: true })
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'are allowed with field options set' do
      blueprint.collection :foos, sub_blueprint, exclude_if_nil: true
      ctx = prepare(blueprint, field, [{ name: 'Foo' }], object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'are excluded with field options set if nil' do
      blueprint.collection :foos, sub_blueprint, exclude_if_nil: true
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'are allowed with blueprint options set' do
      blueprint.options[:exclude_if_nil] = true
      ctx = prepare(blueprint, field, [{ name: 'Foo' }], object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'are excluded with blueprint options set if nil' do
      blueprint.options[:exclude_if_nil] = true
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_collection? ctx).to be true
    end
  end
end
