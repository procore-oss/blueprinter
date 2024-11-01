# frozen_string_literal: true

require 'date'

describe Blueprinter::V2::Formatter do
  let(:field) { Blueprinter::V2::Field.new(name: :foo, from: :foo) }
  let(:object) { { foo: 'Foo' } }
  let(:context) { Blueprinter::V2::Context::Field }
  let(:instances) { Blueprinter::V2::InstanceCache.new }
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
    ctx = context.new(blueprint.new, {}, instances, {}, object, field, Date.new(2024, 10, 1))
    expect(formatter.call(ctx)).to eq '2024-10-01'
  end

  it 'calls instance method formatters' do
    formatter = described_class.new(blueprint)
    ctx = context.new(blueprint.new, {}, instances, {}, object, field, true)
    expect(formatter.call(ctx)).to eq "Yes"
  end

  it "passes through values it doesn't know about" do
    formatter = described_class.new(blueprint)
    ctx = context.new(blueprint.new, {}, instances, {}, object, field, "foo")
    expect(formatter.call(ctx)).to eq "foo"
  end
end
