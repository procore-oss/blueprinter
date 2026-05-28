# frozen_string_literal: true

require 'date'

describe Blueprinter::V2::Formatter do
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      format(Date) { |date| date.iso8601 }
      format TrueClass, :yes

      def yes(_)
        "Yes"
      end
    end
  end

  let(:formatter) do
    blueprint.eval!
    described_class.new(blueprint.formatters)
  end

  it 'calls proc formatters' do
    value = Date.new(2024, 10, 1)
    expect(formatter.call(blueprint.new, value)).to eq '2024-10-01'
  end

  it 'calls instance method formatters' do
    value = true
    expect(formatter.call(blueprint.new, value)).to eq "Yes"
  end

  it "passes through values it doesn't know about" do
    value = "foo"
    expect(formatter.call(blueprint.new, value)).to eq "foo"
  end
end
