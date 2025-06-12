# frozen_string_literal: true

require 'ostruct'

describe Blueprinter::V2::Extensions::Core::Prelude do
  include ExtensionHelpers

  subject { described_class.new }
  let(:context) { Blueprinter::V2::Context::Result }
  let(:instances) { Blueprinter::V2::InstanceCache.new }

  it 'returns all fields in the order they were defined' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
      object :category, self
      collection :parts, self
    end
    serializer = Blueprinter::V2::Serializer.new(blueprint, {}, instances, initial_depth: 1)
    ctx = Blueprinter::V2::Context::Render.new(serializer.blueprint, serializer.fields, {})

    expect(subject.blueprint_fields(ctx).map(&:name)).to eq %i(name category parts)
  end

  it 'outputs json' do
    ctx = context.new(blueprint.new, {}, { 'name' => 'Foo' }, { name: 'Foo' })
    result = subject.json(ctx)
    expect(result).to eq ctx.result.to_json
  end
end
