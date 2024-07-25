# frozen_string_literal: true

require 'blueprinter/association'

describe Blueprinter::Association do
  describe '#initialize' do
    let(:blueprint) { Class.new(Blueprinter::Base) }
    let(:args) do
      {
        method: :method,
        name: :name,
        extractor: :extractor,
        blueprint: blueprint,
        view: :view,
        options: { if: -> { true } }
      }
    end

    it 'returns an instance of Blueprinter::Association' do
      expect(Blueprinter::Association.new(**args)).
        to be_instance_of(Blueprinter::Association)
    end
    context 'when provided :blueprint is invalid' do
      let(:blueprint) { Class.new }

      it 'raises a Blueprinter::InvalidBlueprintError' do
        expect { Blueprinter::Association.new(**args) }.
          to raise_error(Blueprinter::Errors::InvalidBlueprint)
      end
    end

    context 'when an extractor is not provided' do
      it 'defaults to using AssociationExtractor' do
        expect(Blueprinter::Association.new(**args.except(:extractor)).extractor).
          to be_an_instance_of(Blueprinter::AssociationExtractor)
      end
    end
  end
end
