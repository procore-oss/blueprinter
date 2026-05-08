# frozen_string_literal: true

describe Blueprinter::Extensions::ViewOption do
  subject { described_class.new }
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
    blueprint.extensions << subject
    result = blueprint.render({}).to_hash
    expect(result).to eq({})
  end

  it 'finds a nested view' do
    blueprint.extensions << subject
    result = blueprint.render({}, view: 'foo.bar').to_hash
    expect(result).to eq({ foo: nil, bar: nil })
  end
end
