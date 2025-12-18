# frozen_string_literal: true

describe 'Extraction' do
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :foo
    end
  end
  let(:instances) { Blueprinter::V2::InstanceCache.new }
  let(:serializer) { Blueprinter::V2::Serializer.new(blueprint, {}, instances, store: {}, initial_depth: 1) }

  it 'extracts from a Symbol Hash' do
    object = { foo: 'Foo' }
    result = serializer.object(object, depth: 1)
    expect(result).to eq({ foo: 'Foo' })
  end

  it 'extracts from a String Hash' do
    object = { 'foo' => 'Foo' }
    result = serializer.object(object, depth: 1)
    expect(result).to eq({ foo: 'Foo' })
  end

  it 'extracts from an object' do
    object = Struct.new(:foo).new('Foo')
    result = serializer.object(object, depth: 1)
    expect(result).to eq({ foo: 'Foo' })
  end

  it 'extracts using a proc' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field(:foo) { |obj, _ctx| "#{obj[:foo]}!" }
    end
    serializer = Blueprinter::V2::Serializer.new(blueprint, {}, instances, store: {}, initial_depth: 1)

    object = { foo: 'Foo' }
    result = serializer.object(object, depth: 1)
    expect(result).to eq({ foo: 'Foo!' })
  end
end
