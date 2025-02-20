# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Core::Postlude do
  subject { described_class.new }
  let(:context) { Blueprinter::V2::Context }
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :name

      def meta_links
        { links: [] }
      end
    end
  end

  it 'outputs json' do
    ctx = context.new(blueprint.new, nil, { name: 'Foo' }, nil, {})
    result = subject.json(ctx)
    expect(result).to eq ctx.value.to_json
  end
end
