# frozen_string_literal: true

require 'blueprinter/association'

describe Blueprinter::Association do
  describe '#initialize' do
    let(:blueprint) { Class.new(Blueprinter::Base) }
    let(:parent_blueprint) { Class.new(Blueprinter::Base) }
    let(:if_condition) { -> { true } }
    let(:args) do
      {
        method: :method,
        name: :name,
        extractor: :extractor,
        blueprint: blueprint,
        parent_blueprint: parent_blueprint,
        view: :view,
        options: { if: if_condition }
      }
    end

    it 'returns an instance of Blueprinter::Association with expected values', aggregate_failures: true do
      association = described_class.new(**args)
      expect(association).to be_instance_of(described_class)
      expect(association.method).to eq(:method)
      expect(association.name).to eq(:name)
      expect(association.extractor).to eq(:extractor)
      expect(association.blueprint).to eq(parent_blueprint)
      expect(association.options).to eq({ if: if_condition, blueprint: blueprint, view: :view, association: true })
    end

    context 'when provided :blueprint is invalid' do
      let(:blueprint) { Class.new }

      it 'raises a Blueprinter::InvalidBlueprintError' do
        expect { described_class.new(**args) }.
          to raise_error(Blueprinter::Errors::InvalidBlueprint)
      end
    end

    context 'when an extractor is not provided' do
      it 'defaults to using AssociationExtractor' do
        expect(described_class.new(**args.except(:extractor)).extractor).
          to be_an_instance_of(Blueprinter::AssociationExtractor)
      end
    end
  end
end
