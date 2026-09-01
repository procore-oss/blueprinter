# frozen_string_literal: true

require 'blueprinter/empty_types'

describe Blueprinter::Extensions::LegacyDefaultIf do
  subject { described_class.new }
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :name, default: "No name", default_if: ->(_ctx, val) { val.empty? }
      field :desc, default: "No desc", default_if: Blueprinter::EMPTY_STRING
    end
  end

  it 'respects both V1 and V2 options' do
    blueprint.add subject
    result = blueprint.render({ name: '', desc: '' }).to_hash
    expect(result).to eq({ name: 'No name', desc: 'No desc' })
  end
end
