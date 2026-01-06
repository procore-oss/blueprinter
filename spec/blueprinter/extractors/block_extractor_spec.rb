# frozen# frozen_string_literal: true

require 'blueprinter/extractors/block_extractor'

describe Blueprinter::BlockExtractor do
  subject(:extractor) { described_class.new }

  let(:object) do
    Struct.new(:name)
  end
  let(:local_options) { { greeting: 'Hello' } }
  let(:block) do
    Proc.new do |object, local_options|
      local_options[:greeting] + ' ' + object.name
    end
  end

  describe 'extract' do
    it 'calls the block with the provided object and local_options' do
      expect(extractor.extract(nil, object.new('Jake'), local_options, block: block)).to eq('Hello Jake')
    end
  end
end
