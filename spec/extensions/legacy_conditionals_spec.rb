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

  it "passes the field's result name, like V1" do
    names = []
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :description, name: :desc, if: ->(field, _object, _options) { names << field }
    end
    blueprint.add subject
    blueprint.render({ description: 'Foo' }).to_hash
    expect(names).to eq [:desc]
  end

  it 'treats callables with optional and splat args as V1' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :optional, if: ->(_field, object, _options = {}) { object[:name] == 'Foo' }
      field :splat, if: ->(*args) { args[1][:name] == 'Foo' }
      field :optional_method, if: :show?
      field :private_method, if: :also_show?

      def self.show?(_field, object, _options = {}) = object[:name] == 'Foo'
      def self.also_show?(_field, object, _options) = object[:name] == 'Foo'
      private_class_method :also_show?
    end
    blueprint.add subject
    result = blueprint.render({ name: 'Foo', optional: 1, splat: 2, optional_method: 3, private_method: 4 }).to_hash
    expect(result).to eq({ optional: 1, splat: 2, optional_method: 3, private_method: 4 })
  end

  it "doesn't treat the class methods every Blueprint has as V1 conditionals" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name, if: :format
      def format(_ctx) = true
    end
    blueprint.add subject
    expect(blueprint.render({ name: 'Foo' }).to_hash).to eq({ name: 'Foo' })
  end
end
