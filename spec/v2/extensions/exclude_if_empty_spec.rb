# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Exclusions do
  include ExtensionHelpers
  let(:object) { { foo: 'Foo' } }

  context 'fields' do
    let(:field) { blueprint.reflections[:default].fields[:foo] }

    it 'should be allowed by default' do
      ctx = prepare(blueprint, field, 'Foo', object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should be allowed by default if nil' do
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should be allowed with options set' do
      ctx = prepare(blueprint, field, 'Foo', object, { exclude_if_empty: true })
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should be excluded with options set if nil' do
      ctx = prepare(blueprint, field, nil, object, { exclude_if_empty: true })
      expect(subject.exclude_field? ctx).to be true
    end

    it 'should be excluded with options set if empty' do
      ctx = prepare(blueprint, field, [], object, { exclude_if_empty: true })
      expect(subject.exclude_field? ctx).to be true
    end

    it 'should be allowed with field options set' do
      blueprint.field :foo, exclude_if_empty: true
      ctx = prepare(blueprint, field, 'Foo', object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should be excluded with field options set if nil' do
      blueprint.field :foo, exclude_if_empty: true
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_field? ctx).to be true
    end

    it 'should be excluded with field options set if empty' do
      blueprint.field :foo, exclude_if_empty: true
      ctx = prepare(blueprint, field, [], object, {})
      expect(subject.exclude_field? ctx).to be true
    end

    it 'should be allowed with blueprint options set' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, field, 'Foo', object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should be excluded with blueprint options set if nil' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_field? ctx).to be true
    end

    it 'should be excluded with blueprint options set if empty' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, field, [], object, {})
      expect(subject.exclude_field? ctx).to be true
    end
  end

  context 'objects' do
    let(:field) { blueprint.reflections[:default].objects[:foo_obj] }

    it 'should be allowed by default' do
      ctx = prepare(blueprint, field, { name: 'Foo' }, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should be allowed by default if nil' do
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should be allowed with options set' do
      ctx = prepare(blueprint, field, { name: 'Foo' }, object, { exclude_if_empty: true })
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should be excluded with options set if nil' do
      ctx = prepare(blueprint, field, nil, object, { exclude_if_empty: true })
      expect(subject.exclude_object? ctx).to be true
    end

    it 'should be excluded with options set if empty' do
      ctx = prepare(blueprint, field, {}, object, { exclude_if_empty: true })
      expect(subject.exclude_object? ctx).to be true
    end

    it 'should be allowed with field options set' do
      blueprint.object :foo_obj, sub_blueprint, exclude_if_empty: true
      ctx = prepare(blueprint, field, { name: 'Foo' }, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should be excluded with field options set if nil' do
      blueprint.object :foo_obj, sub_blueprint, exclude_if_empty: true
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_object? ctx).to be true
    end

    it 'should be excluded with field options set if empty' do
      blueprint.object :foo_obj, sub_blueprint, exclude_if_empty: true
      ctx = prepare(blueprint, field, {}, object, {})
      expect(subject.exclude_object? ctx).to be true
    end

    it 'should be allowed with blueprint options set' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, field, { name: 'Foo' }, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should be excluded with blueprint options set if nil' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_object? ctx).to be true
    end

    it 'should be excluded with blueprint options set if empty' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, field, {}, object, {})
      expect(subject.exclude_object? ctx).to be true
    end
  end

  context 'collections' do
    let(:field) { blueprint.reflections[:default].collections[:foos] }

    it 'should be allowed by default' do
      ctx = prepare(blueprint, field, [{ name: 'Foo' }], object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should be allowed by default if nil' do
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should be allowed with options set' do
      ctx = prepare(blueprint, field, [{ name: 'Foo' }], object, { exclude_if_empty: true })
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should be excluded with options set if nil' do
      ctx = prepare(blueprint, field, nil, object, { exclude_if_empty: true })
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'should be excluded with options set if empty' do
      ctx = prepare(blueprint, field, [], object, { exclude_if_empty: true })
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'should be allowed with field options set' do
      blueprint.collection :foos, sub_blueprint, exclude_if_empty: true
      ctx = prepare(blueprint, field, [{ name: 'Foo' }], object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should be excluded with field options set if nil' do
      blueprint.collection :foos, sub_blueprint, exclude_if_empty: true
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'should be excluded with field options set if empty' do
      blueprint.collection :foos, sub_blueprint, exclude_if_empty: true
      ctx = prepare(blueprint, field, [], object, {})
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'should be allowed with blueprint options set' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, field, [{ name: 'Foo' }], object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should be excluded with blueprint options set if nil' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'should be excluded with blueprint options set if empty' do
      blueprint.options[:exclude_if_empty] = true
      ctx = prepare(blueprint, field, [], object, {})
      expect(subject.exclude_collection? ctx).to be true
    end
  end
end
