# frozen_string_literal: true

describe Blueprinter::Extensions::FieldOrder do
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :foo
      field :id
      association :bar, self
    end
  end

  it 'sorts fields alphabetically' do
    blueprint.extensions << described_class.new { |a, b| a.name <=> b.name }
    result = blueprint.render({}).to_json
    expect(result).to eq '{"bar":null,"foo":null,"id":null}'
  end

  it 'sorts fields alphabetically with id first' do
    blueprint.extensions << described_class.new do |a, b|
      if a.name == :id
        -1
      elsif b.name == :id
        1
      else
        a.name <=> b.name
      end
    end
    result = blueprint.render({}).to_json
    expect(result).to eq '{"id":null,"bar":null,"foo":null}'
  end
end
