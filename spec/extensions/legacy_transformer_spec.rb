# frozen_string_literal: true

describe Blueprinter::Extensions::LegacyTransformer do
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      fields :id, :name
    end
  end

  let(:transformer1) do
    Class.new do
      def transform(hash, object, options)
        hash.transform_values!(&:to_s)
      end
    end
  end

  let(:transformer2) do
    Class.new do
      def transform(hash, object, options)
        hash.transform_values!(&:downcase)
      end
    end
  end

  it 'applies mutliple transformers' do
    blueprint.extensions << described_class.new(transformer1, transformer2)
    result = blueprint.render({ id: 42, name: 'Foo' }).to_hash
    expect(result).to eq({ id: '42', name: 'foo' })
  end
end
