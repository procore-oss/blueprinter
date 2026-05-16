# frozen_string_literal: true

describe Blueprinter::Extensions::LegacyRenameField do
  subject { described_class.new }
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :name
      field :desc_v2, source: :description_v2
      field :description_v1, name: :desc_v1
    end
  end

  it "respects V1's name option" do
    blueprint.extensions << subject
    result = blueprint.render({
      name: 'Foo',
      description_v2: 'Desc V2',
      description_v1: 'Desc V1'
    }).to_hash

    expect(result).to eq({
      name: 'Foo',
      desc_v2: 'Desc V2',
      desc_v1: 'Desc V1'
    })
  end
end
