# frozen_string_literal: true

require 'blueprinter/extractors/public_send_extractor'

describe Blueprinter::PublicSendExtractor do
  subject(:extractor) { described_class.new }

  let(:object) do
    Class.new(Object) do
      def speak
        'Hello there!'
      end
    end
  end
  let(:field_name) { :speak }

  describe 'extract' do
    it 'calls the field_name as a method on the provided object' do
      expect(extractor.extract(field_name, object.new)).to eq('Hello there!')
    end

    context 'when the object does not respond to the field_name' do
      it 'raises an error' do
        expect { extractor.extract(:listen, object.new) }.to raise_error(NoMethodError)
      end
    end
  end
end
