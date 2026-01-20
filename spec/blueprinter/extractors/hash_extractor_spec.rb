# frozen# frozen_string_literal: true

require 'blueprinter/extractors/hash_extractor'

describe Blueprinter::HashExtractor do
  subject(:extractor) { described_class.new }

  let(:hash) do
    {
      speak: 'Hello there!'
    }
  end
  let(:field_name) { :speak }

  describe 'extract' do
    it 'uses the field_name as a key on the provided Hash' do
      expect(extractor.extract(field_name, hash)).to eq('Hello there!')
    end

    context 'when the field_name is not a key in the Hash' do
      it 'returns nil' do
        expect(extractor.extract(:listen, hash)).to be_nil
      end
    end
  end
end
