# frozen_string_literal: true

require 'blueprinter/empty_types'

describe Blueprinter::Extensions::LegacyExtractorOption do
  subject { described_class.new }
  let(:extractor) do
    Class.new do
      def extract(field_name, object, local_options, options)
        "Extracted: #{object[field_name]}"
      end
    end
  end

  let(:extractor2) do
    Class.new do
      def extract(field_name, object, local_options, options)
        "Xtracted: #{object[field_name]}"
      end
    end
  end

  let(:blueprint) do
    extractor = self.extractor
    extractor2 = self.extractor2
    Class.new(Blueprinter::V2::Base) do
      field :name
      field :desc, extractor: extractor

      view :with_extractor do
        options[:extractor] = extractor
        field :foo, extractor: extractor2
      end
    end
  end

  it 'respects the field option' do
    blueprint.extensions << subject
    result = blueprint.render({ name: 'foo', desc: 'bar' }).to_hash
    expect(result).to eq({ name: 'foo', desc: 'Extracted: bar' })
  end

  it 'respects the blueprint option' do
    blueprint.extensions << subject
    result = blueprint[:with_extractor].render({ name: 'foo', desc: 'bar', foo: 'asdf' }).to_hash
    expect(result).to eq({
      name: 'Extracted: foo',
      desc: 'Extracted: bar',
      foo: 'Xtracted: asdf'
    })
  end
end
