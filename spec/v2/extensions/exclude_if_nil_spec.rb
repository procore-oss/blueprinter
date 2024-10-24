# frozen_string_literal: true

describe Blueprinter::V2::Extensions::ExcludeIfNil do
  subject { described_class.new }
  let(:context) { Blueprinter::V2::Serializer::Context }
  let(:blueprint) { Class.new(Blueprinter::V2::Base) }
  let(:field) { Blueprinter::V2::Field.new(name: :name, from: :name, options: {}) }
  let(:object) { { name: 'Foo' } }

  context 'fields' do
    it 'should be allowed by default' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should be allowed by default if nil' do
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should be allowed with options set' do
      ctx = context.new(blueprint.new, field, 'Foo', object, { exclude_if_nil: true })
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should be excluded with options set if nil' do
      ctx = context.new(blueprint.new, field, nil, object, { exclude_if_nil: true })
      expect(subject.exclude_field? ctx).to be true
    end

    it 'should be allowed with field options set' do
      field.options[:exclude_if_nil] = true
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should be excluded with field options set if nil' do
      field.options[:exclude_if_nil] = true
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.exclude_field? ctx).to be true
    end

    it 'should be allowed with blueprint options set' do
      blueprint.options[:exclude_if_nil] = true
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.exclude_field? ctx).to be false
    end

    it 'should be excluded with blueprint options set if nil' do
      blueprint.options[:exclude_if_nil] = true
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.exclude_field? ctx).to be true
    end
  end

  context 'objects' do
    it 'should be allowed by default' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should be allowed by default if nil' do
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should be allowed with options set' do
      ctx = context.new(blueprint.new, field, 'Foo', object, { exclude_if_nil: true })
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should be excluded with options set if nil' do
      ctx = context.new(blueprint.new, field, nil, object, { exclude_if_nil: true })
      expect(subject.exclude_object? ctx).to be true
    end

    it 'should be allowed with field options set' do
      field.options[:exclude_if_nil] = true
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should be excluded with field options set if nil' do
      field.options[:exclude_if_nil] = true
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.exclude_object? ctx).to be true
    end

    it 'should be allowed with blueprint options set' do
      blueprint.options[:exclude_if_nil] = true
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.exclude_object? ctx).to be false
    end

    it 'should be excluded with blueprint options set if nil' do
      blueprint.options[:exclude_if_nil] = true
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.exclude_object? ctx).to be true
    end
  end

  context 'collections' do
    it 'should be allowed by default' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should be allowed by default if nil' do
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should be allowed with options set' do
      ctx = context.new(blueprint.new, field, 'Foo', object, { exclude_if_nil: true })
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should be excluded with options set if nil' do
      ctx = context.new(blueprint.new, field, nil, object, { exclude_if_nil: true })
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'should be allowed with field options set' do
      field.options[:exclude_if_nil] = true
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should be excluded with field options set if nil' do
      field.options[:exclude_if_nil] = true
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.exclude_collection? ctx).to be true
    end

    it 'should be allowed with blueprint options set' do
      blueprint.options[:exclude_if_nil] = true
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.exclude_collection? ctx).to be false
    end

    it 'should be excluded with blueprint options set if nil' do
      blueprint.options[:exclude_if_nil] = true
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.exclude_collection? ctx).to be true
    end
  end
end
