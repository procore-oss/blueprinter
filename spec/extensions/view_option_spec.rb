# frozen_string_literal: true

describe Blueprinter::Extensions::LegacyOptions do
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
    blueprint.add subject
    result = blueprint.render({}).to_hash
    expect(result).to eq({})
  end

  it 'finds a nested view' do
    blueprint.add subject
    result = blueprint.render({}, view: 'foo.bar').to_hash
    expect(result).to eq({ foo: nil, bar: nil })
  end

  it 'leaves the option in the options hash, like V1' do
    options = []
    blueprint = Class.new(Blueprinter::V2::Base) do
      view :foo do
        field :foo, if: ->(_field, _object, opts) { options << opts[:view] }
      end
    end
    blueprint.add subject
    blueprint.render({}, view: :foo).to_hash
    expect(options).to eq [:foo]
  end
end
