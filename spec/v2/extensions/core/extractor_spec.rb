# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Core::Extractor do
  include ExtensionHelpers

  let(:field) { blueprint.reflections[:default].fields[:foo] }

  it 'extracts from a Symbol Hash' do
    object = { foo: 'Foo' }
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
    value = subject.around_field_value(ctx)
    expect(value).to eq 'Foo'
  end

  it 'extracts from a String Hash' do
    object = { 'foo' => 'Foo' }
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
    value = subject.around_field_value(ctx)
    expect(value).to eq 'Foo'
  end

  it 'extracts from an object' do
    object = Struct.new(:foo).new('Foo')
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
    value = subject.around_field_value(ctx)
    expect(value).to eq 'Foo'
  end

  it 'extracts an object' do
    object = { foo_obj: { name: 'Bar' } }
    field = blueprint.reflections[:default].objects[:foo_obj]
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
    value = subject.around_object_value(ctx)
    expect(value).to eq({ name: 'Bar' })
  end

  it 'extracts a collection' do
    object = { foos: [{ num: 42 }] }
    field = blueprint.reflections[:default].collections[:foos]
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
    value = subject.around_collection_value(ctx)
    expect(value).to eq([{ num: 42 }])
  end

  it 'extracts using a proc' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      self.blueprint_name = 'TestBlueprint'
      field(:foo) { |ctx| msg ctx.object }
      def msg(obj) = "It's a proc! #{obj[:name]}"
    end
    field = blueprint.reflections[:default].fields[:foo]
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, { name: 'Foo' }, field)
    value = subject.around_field_value(ctx)
    expect(value).to eq "It's a proc! Foo"
  end

  it "shouldn't hide subclasses" do
    sub = Class.new(described_class)
    expect(sub.new.hidden?).to be false
  end
end
