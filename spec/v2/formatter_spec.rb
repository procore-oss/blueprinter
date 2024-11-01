# frozen_string_literal: true

require 'date'

describe Blueprinter::V2::Formatter do
  let(:field) { Blueprinter::V2::Field.new(name: :foo, from: :foo) }
  let(:object) { { foo: 'Foo' } }
  let(:context) { Blueprinter::V2::Context }
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      format(Date) { |date| date.iso8601 }
      format TrueClass, :yes

      def yes(_)
        "Yes"
      end
    end
  end

  it 'calls proc formatters' do
    formatter = described_class.new(blueprint)
    expect(formatter.call(context.new(blueprint.new, field, Date.new(2024, 10, 1), object, {}))).to eq '2024-10-01'
  end

  it 'calls instance method formatters' do
    formatter = described_class.new(blueprint)
    expect(formatter.call(context.new(blueprint.new, field, true, object, {}))).to eq "Yes"
  end

  it "passes through values it doesn't know about" do
    formatter = described_class.new(blueprint)
    expect(formatter.call(context.new(blueprint.new, field, "foo", object, {}))).to eq "foo"
  end
end
