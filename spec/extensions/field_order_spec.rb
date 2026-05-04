# frozen_string_literal: true

describe Blueprinter::Extensions::FieldOrder do
  let(:instances) { Blueprinter::V2::InstanceCache.new }
  let(:serializer) { blueprint.serializer }
  let(:context) { Blueprinter::V2::Context::Init.new(instances.blueprint(blueprint), blueprint.options, serializer.default_fields, {}, 1) }
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :foo
      field :id
      association :bar, self
    end
  end

  it 'sorts fields alphabetically' do
    ext = described_class.new { |a, b| a.name <=> b.name }
    ctx = ext.around_blueprint_init(context) { |ctx| ctx }
    expect(ctx.fields.map(&:name)).to eq %i(bar foo id)
  end

  it 'sorts fields alphabetically with id first' do
    ext = described_class.new do |a, b|
      if a.name == :id
        -1
      elsif b.name == :id
        1
      else
        a.name <=> b.name
      end
    end
    ctx = ext.around_blueprint_init(context) { |ctx| ctx }
    expect(ctx.fields.map(&:name)).to eq %i(id bar foo)
  end
end
