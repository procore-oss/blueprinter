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

  it 'defaults to nil when there is no default, like V1' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name, default_if: Blueprinter::EMPTY_STRING
      field :desc, default_if: ->(_ctx, val) { val.empty? }
    end
    blueprint.add subject
    # V2's default_if is still ignored when there's no default
    expect(blueprint.render({ name: '', desc: '' }).to_hash).to eq({ name: nil, desc: '' })
  end

  it "ignores V1's global field_default config" do
    blueprint = Class.new(Blueprinter::V2::Base) { field :name, default_if: Blueprinter::EMPTY_STRING }
    blueprint.add subject
    allow(Blueprinter.configuration).to receive(:field_default).and_return('N/A')
    expect(blueprint.render({ name: '' }).to_hash).to eq({ name: nil })
  end

  it "doesn't override a blueprint-level default" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      set :default, 'None'
      field :name, default_if: Blueprinter::EMPTY_STRING
    end
    blueprint.add subject
    expect(blueprint.render({ name: '' }).to_hash).to eq({ name: 'None' })
  end
end
