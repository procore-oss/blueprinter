# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Core::Extractor do
  include ExtensionHelpers

  let(:field) { blueprint.reflections[:default].fields[:foo] }

  it 'extracts from a Symbol Hash' do
    object = { foo: 'Foo' }
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
    expect(subject.extract_value ctx).to eq 'Foo'
  end

  it 'extracts from a String Hash' do
    object = { 'foo' => 'Foo' }
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
    expect(subject.extract_value ctx).to eq 'Foo'
  end

  it 'extracts from an object' do
    object = Struct.new(:foo).new('Foo')
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
    expect(subject.extract_value ctx).to eq 'Foo'
  end

  it 'extracts an object' do
    object = { foo_obj: { name: 'Bar' } }
    field = blueprint.reflections[:default].objects[:foo_obj]
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
    expect(subject.extract_value ctx).to eq({ name: 'Bar' })
  end

  it 'extracts a collection' do
    object = { foos: [{ num: 42 }] }
    field = blueprint.reflections[:default].collections[:foos]
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, nil)
    expect(subject.extract_value ctx).to eq([{ num: 42 }])
  end
end
