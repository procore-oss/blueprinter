# frozen_string_literal: true

describe Blueprinter::Extensions::LegacyConditionals do
  subject { described_class.new }
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :name
      # All conditionals are designed to hide their fields
      field :desc_if, if: ->(_ctx) { false }
      field :desc_unless, unless: ->(_ctx) { true }
      field :legacy_desc_if, if: ->(field, object, _options) do
        field != :legacy_desc_if || object[:name] != 'Foo'
      end
      field :legacy_desc_unless, unless: ->(field, object, _options) do
        field == :legacy_desc_unless && object[:name] == 'Foo'
      end
    end
  end

  it 'respects both V1 and V2 conditionals' do
    blueprint.extensions { |exts| exts << subject }
    result = blueprint.render({ name: 'Foo' }).to_hash
    expect(result).to eq({ name: 'Foo' })
  end
end
