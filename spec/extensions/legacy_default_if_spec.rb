# frozen_string_literal: true

require 'blueprinter/empty_types'

describe Blueprinter::Extensions::LegacyOptions do
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

  it "doesn't apply defaults to nil unless default_if says so, like V1" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name, default: 'No name', default_if: Blueprinter::EMPTY_COLLECTION
      field :desc, default: 'No desc', default_if: Blueprinter::EMPTY_STRING
    end
    blueprint.add subject
    result = blueprint.render({ name: nil, desc: nil }).to_hash
    expect(result).to eq({ name: nil, desc: 'No desc' })
  end
end
