# frozen_string_literal: true

describe Blueprinter::Extensions::FieldOrder do
  let(:context) { Blueprinter::V2::Context::Render.new(blueprint.new, {}, instances, {}) }
  let(:instances) { Blueprinter::V2::InstanceCache.new }
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :foo
      field :id
      object :bar, self
    end
  end

  it 'sorts fields alphabetically' do
    ext = described_class.new { |a, b| a.name <=> b.name }
    result = ext.blueprint_fields(context)
    expect(result.map(&:name)).to eq %i(bar foo id)
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
    result = ext.blueprint_fields(context)
    expect(result.map(&:name)).to eq %i(id bar foo)
  end
end
