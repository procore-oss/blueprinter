# frozen_string_literal: true

describe Blueprinter::Extension do
  subject { Class.new(described_class) }

  context 'hooks' do
    let(:blueprint) { Class.new(Blueprinter::V2::Base) }
    let(:field) { Blueprinter::V2::Field.new(name: :foo, from: :foo) }
    let(:object) { { foo: 'Foo' } }
    let(:context) { Blueprinter::V2::Context }

    it 'should yield on around_render' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      res = subject.new.around_render(ctx) { |_ctx| true }
      expect(res).to be true
    end

    it 'should yield on around_object_serialization' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      res = subject.new.around_object_serialization(ctx) { |_ctx| true }
      expect(res).to be true
    end

    it 'should yield on around_collection_serialization' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      res = subject.new.around_collection_serialization(ctx) { |_ctx| true }
      expect(res).to be true
    end

    it 'should default to doing nothing on prepare' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.prepare(ctx)).to be nil
    end

    it 'should default to no fields' do
      ctx = context.new(blueprint.new, nil, nil, object, {})
      expect(subject.new.blueprint_fields(ctx)).to eq []
    end

    it 'should default input_object to the given object' do
      ctx = context.new(blueprint.new, nil, nil, object, {})
      expect(subject.new.input_object(ctx)).to eq object
    end

    it 'should default input_collection to the given object' do
      ctx = context.new(blueprint.new, nil, nil, [object], {})
      expect(subject.new.input_object(ctx)).to eq [object]
    end

    it 'should default output_object to the given value' do
      ctx = context.new(blueprint.new, nil, { foo: 'Foo' }, object, {})
      expect(subject.new.output_object(ctx)).to eq({ foo: 'Foo' })
    end

    it 'should default output_collection to the given value' do
      ctx = context.new(blueprint.new, nil, [{ foo: 'Foo' }], [object], {})
      expect(subject.new.output_collection(ctx)).to eq([{ foo: 'Foo' }])
    end

    it 'should default blueprint_input to the given object' do
      ctx = context.new(blueprint.new, nil, nil, object, {})
      expect(subject.new.blueprint_input(ctx)).to eq object
    end

    it 'should default blueprint_output to the given value' do
      ctx = context.new(blueprint.new, nil, { foo: 'Foo' }, object, {})
      expect(subject.new.blueprint_output(ctx)).to eq({ foo: 'Foo' })
    end

    it 'should default field_value to the given value' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.field_value(ctx)).to be 'Foo'
    end

    it 'should default object_value to the given value' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.object_value(ctx)).to be 'Foo'
    end

    it 'should default collection_value to the given value' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.collection_value(ctx)).to be 'Foo'
    end

    it 'should default exclude_field? to false' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.exclude_field?(ctx)).to be false
    end

    it 'should default exclude_object? to false' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.exclude_object?(ctx)).to be false
    end

    it 'should default exclude_collection? to false' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.exclude_collection?(ctx)).to be false
    end

    it 'should default json to nil' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.json(ctx)).to be nil
    end
  end
end
