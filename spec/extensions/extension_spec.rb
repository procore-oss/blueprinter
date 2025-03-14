# frozen_string_literal: true

describe Blueprinter::Extension do
  subject { Class.new(described_class) }

  context 'hooks' do
    let(:blueprint) { Class.new(Blueprinter::V2::Base) }
    let(:field) { Blueprinter::V2::Field.new(name: :foo, from: :foo) }
    let(:object) { { foo: 'Foo' } }
    let(:context) { Blueprinter::V2::Context }

    it 'yields on around_render' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      res = subject.new.around_render(ctx) { |_ctx| true }
      expect(res).to be true
    end

    it 'yields on around_object_serialization' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      res = subject.new.around_object_serialization(ctx) { |_ctx| true }
      expect(res).to be true
    end

    it 'yields on around_collection_serialization' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      res = subject.new.around_collection_serialization(ctx) { |_ctx| true }
      expect(res).to be true
    end

    it 'defaults to doing nothing on prepare' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.prepare(ctx)).to be nil
    end

    it 'defaults to no fields' do
      ctx = context.new(blueprint.new, nil, nil, object, {})
      expect(subject.new.blueprint_fields(ctx)).to eq []
    end

    it 'defaults input_object to the given object' do
      ctx = context.new(blueprint.new, nil, nil, object, {})
      expect(subject.new.input_object(ctx)).to eq object
    end

    it 'defaults input_collection to the given object' do
      ctx = context.new(blueprint.new, nil, nil, [object], {})
      expect(subject.new.input_object(ctx)).to eq [object]
    end

    it 'defaults output_object to the given value' do
      ctx = context.new(blueprint.new, nil, { foo: 'Foo' }, object, {})
      expect(subject.new.output_object(ctx)).to eq({ foo: 'Foo' })
    end

    it 'defaults output_collection to the given value' do
      ctx = context.new(blueprint.new, nil, [{ foo: 'Foo' }], [object], {})
      expect(subject.new.output_collection(ctx)).to eq([{ foo: 'Foo' }])
    end

    it 'defaults blueprint_input to the given object' do
      ctx = context.new(blueprint.new, nil, nil, object, {})
      expect(subject.new.blueprint_input(ctx)).to eq object
    end

    it 'defaults blueprint_output to the given value' do
      ctx = context.new(blueprint.new, nil, { foo: 'Foo' }, object, {})
      expect(subject.new.blueprint_output(ctx)).to eq({ foo: 'Foo' })
    end

    it 'defaults field_value to the given value' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.field_value(ctx)).to be 'Foo'
    end

    it 'defaults object_value to the given value' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.object_value(ctx)).to be 'Foo'
    end

    it 'defaults collection_value to the given value' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.collection_value(ctx)).to be 'Foo'
    end

    it 'defaults exclude_field? to false' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.exclude_field?(ctx)).to be false
    end

    it 'defaults exclude_object? to false' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.exclude_object?(ctx)).to be false
    end

    it 'defaults exclude_collection? to false' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.exclude_collection?(ctx)).to be false
    end

    it 'defaults json to nil' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.json(ctx)).to be nil
    end
  end
end
