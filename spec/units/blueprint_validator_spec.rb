# frozen_string_literal: true

describe Blueprinter::BlueprintValidator do
  describe 'validate!' do
    context 'when provided object subclasses Blueprinter::Base' do
      it 'returns true' do
        expect(described_class.validate!(Class.new(Blueprinter::Base))).to eq(true)
      end
    end

    context 'when provided object is a Proc' do
      it 'returns true' do
        expect(
          described_class.validate!(
            -> (obj) { obj }
          )
        ).to eq(true)
      end
    end

    context 'when provided object is not a class nor a Proc' do
      it 'raises a Blueprinter::Errors::InvalidBlueprint exception' do
        expect { described_class.validate!({}) }.
          to raise_error(Blueprinter::Errors::InvalidBlueprint) do
            '{} is not a valid blueprint. Please ensure it subclasses Blueprinter::Base or is a Proc.'
          end
      end
    end

    context 'when provided object is not a Proc nor inherits from Blueprinter::Base' do
      it 'raises a Blueprinter::Errors::InvalidBlueprint exception' do
        expect { described_class.validate!(Integer) }.
          to raise_error(Blueprinter::Errors::InvalidBlueprint) do
            'Integer is not a valid blueprint. Please ensure it subclasses Blueprinter::Base or is a Proc.'
          end
      end
    end
  end
end
