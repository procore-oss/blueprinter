# frozen_string_literal: true

require 'date'

describe Blueprinter::V2::Formatter do
  let(:field) { Blueprinter::V2::Fields::Field.new(name: :foo, from: :foo, from_str: 'foo') }
  let(:object) { { foo: 'Foo' } }
  let(:context) { Blueprinter::V2::Context::Field }
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
    value = Date.new(2024, 10, 1)
    ctx = context.new(blueprint.new, [], {}, object, field)
    expect(formatter.call(value, ctx)).to eq '2024-10-01'
  end

  it 'calls instance method formatters' do
    formatter = described_class.new(blueprint)
    value = true
    ctx = context.new(blueprint.new, [], {}, object, field)
    expect(formatter.call(value, ctx)).to eq "Yes"
  end

  it "passes through values it doesn't know about" do
    formatter = described_class.new(blueprint)
    value = "foo"
    ctx = context.new(blueprint.new, [], {}, object, field)
    expect(formatter.call(value, ctx)).to eq "foo"
  end
end
