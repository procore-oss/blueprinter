# frozen_string_literal: true

describe 'Extraction' do
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :foo
    end
  end
  let(:store) { {} }
  let(:instances) { Blueprinter::V2::InstanceCache.new }
  let(:serializer) { blueprint.serializer }

  it 'extracts from a Symbol Hash' do
    object = { foo: 'Foo' }
    result = serializer.object(object, {}, instances:, store:, depth: 1)
    expect(result).to eq({ foo: 'Foo' })
  end

  it 'extracts from a String Hash' do
    object = { 'foo' => 'Foo' }
    result = serializer.object(object, {}, instances:, store:, depth: 1)
    expect(result).to eq({ foo: 'Foo' })
  end

  it 'extracts from an object' do
    object = Struct.new(:foo).new('Foo')
    result = serializer.object(object, {}, instances:, store:, depth: 1)
    expect(result).to eq({ foo: 'Foo' })
  end

  it 'extracts using a block with zero args' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field(:foo) { "!" }
    end

    object = { foo: 'Foo' }
    result = blueprint.serializer.object(object, {}, instances:, store:, depth: 1)
    expect(result).to eq({ foo: '!' })
  end

  it 'extracts using a block with one arg' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field(:foo) { |obj| "#{obj[:foo]}!" }
    end

    object = { foo: 'Foo' }
    result = blueprint.serializer.object(object, {}, instances:, store:, depth: 1)
    expect(result).to eq({ foo: 'Foo!' })
  end

  it 'extracts using a block with two args' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field(:foo) { |obj, ctx| "#{obj[ctx.field.source]}!" }
    end

    object = { foo: 'Foo' }
    result = blueprint.serializer.object(object, {}, instances:, store:, depth: 1)
    expect(result).to eq({ foo: 'Foo!' })
  end

  it 'extracts using a block with one+ args' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field(:foo) do |obj, *args|
        ctx = args[0]
        "#{obj[ctx.field.source]}!"
      end
    end

    object = { foo: 'Foo' }
    result = blueprint.serializer.object(object, {}, instances:, store:, depth: 1)
    expect(result).to eq({ foo: 'Foo!' })
  end

  it 'extracts using a block with N args' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field(:foo) do |*args|
        obj = args[0]
        ctx = args[1]
        "#{obj[ctx.field.source]}!"
      end
    end

    object = { foo: 'Foo' }
    result = blueprint.serializer.object(object, {}, instances:, store:, depth: 1)
    expect(result).to eq({ foo: 'Foo!' })
  end
end
