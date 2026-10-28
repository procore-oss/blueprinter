# frozen_string_literal: true

describe Blueprinter::Extensions::LegacyOptions do
  subject { described_class.new }
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :name
      # All conditionals are designed to hide their fields when the name is "Foo"
      field :desc_if, if: ->(_ctx) { false }
      field :desc_unless, unless: :always_true
      field :legacy_desc_if, if: ->(field, object, _options) do
        field != :legacy_desc_if || object[:name] != 'Foo'
      end
      field :legacy_desc_unless, unless: ->(field, object, _options) do
        field == :legacy_desc_unless && object[:name] == 'Foo'
      end
      field :legacy_desc_if_method, if: :show_legacy_desc?
      field :legacy_desc_unless_method, unless: 'hide_legacy_desc?'

      def always_true(_ctx) = true

      def self.show_legacy_desc?(field, object, _options)
        field != :legacy_desc_if_method || object[:name] != 'Foo'
      end

      def self.hide_legacy_desc?(field, object, _options)
        field == :legacy_desc_unless_method && object[:name] == 'Foo'
      end
    end
  end

  it 'respects both V1 and V2 conditionals' do
    blueprint.add subject
    result = blueprint.render({ name: 'Foo' }).to_hash
    expect(result).to eq({ name: 'Foo' })
  end

  it 'passes the field name, object, and options to V1 conditionals' do
    blueprint.add subject
    result = blueprint.render({ name: 'Bar' }).to_hash
    expect(result).to eq({
      name: 'Bar',
      legacy_desc_if: nil,
      legacy_desc_unless: nil,
      legacy_desc_if_method: nil,
      legacy_desc_unless_method: nil
    })
  end
end
