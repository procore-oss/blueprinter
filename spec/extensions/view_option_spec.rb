# frozen_string_literal: true

describe Blueprinter::Extensions::ViewOption do
  let(:instances) { Blueprinter::V2::InstanceCache.new }
  let(:serializer) { Blueprinter::V2::Serializer.new(blueprint, {}, instances, initial_depth: 1) }
  let(:context) { Blueprinter::V2::Context::Render }
  let(:object) { { id: 42, foo: 'Foo', bar: 'Bar' } }
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      view :foo do
        field :foo
        view :bar do
          field :bar
        end
      end
    end
  end

  it 'does nothing by default' do
    ctx = context.new(serializer.blueprint, [], {}, 1)
    klass = described_class.new.blueprint ctx
    expect(klass).to be blueprint
  end

  it 'finds a nested view' do
    ctx = context.new(serializer.blueprint, [], { view: 'foo.bar' }, 1)
    klass = described_class.new.blueprint ctx
    expect(klass).to be blueprint['foo.bar']
  end
end
