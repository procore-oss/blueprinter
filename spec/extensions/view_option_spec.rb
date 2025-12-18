# frozen_string_literal: true

describe Blueprinter::Extensions::ViewOption do
  let(:instances) { Blueprinter::V2::InstanceCache.new }
  let(:serializer) { Blueprinter::V2::Serializer.new(blueprint, {}, instances, store: {}, initial_depth: 1) }
  let(:context) { Blueprinter::V2::Context::Result }
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
    ctx = context.new(serializer.blueprint, [], {}, :json)
    new_ctx = described_class.new.around_result(ctx) { |ctx| ctx }
    expect(new_ctx.blueprint.class).to be serializer.blueprint.class
  end

  it 'finds a nested view' do
    ctx = context.new(serializer.blueprint, [], { view: 'foo.bar' }, :json)
    new_ctx = described_class.new.around_result(ctx) { |ctx| ctx }
    expect(new_ctx.blueprint.class).to be blueprint['foo.bar']
  end
end
