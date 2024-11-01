# frozen_string_literal: true

describe Blueprinter::V2::Extensions::FieldOrder do
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :foo
      field :id
      object :bar, self
    end
  end

  it 'should sort fields alphabetically' do
    ext = described_class.new { |a, b| a.name <=> b.name }
    result = ext.sort_fields(blueprint.schema.values)
    expect(result.map(&:name)).to eq %i(bar foo id)
  end

  it 'should sort fields alphabetically with id first' do
    ext = described_class.new do |a, b|
      if a.name == :id
        -1
      elsif b.name == :id
        1
      else
        a.name <=> b.name
      end
    end
    result = ext.sort_fields(blueprint.schema.values)
    expect(result.map(&:name)).to eq %i(id bar foo)
  end
end
