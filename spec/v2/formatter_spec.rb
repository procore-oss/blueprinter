# frozen_string_literal: true

require 'date'

describe Blueprinter::V2::Formatter do
  let(:blueprint) { Class.new(Blueprinter::V2::Base) }
  let(:field) { Blueprinter::V2::Field.new(name: :foo, from: :foo) }
  let(:object) { { foo: 'Foo' } }
  let(:context) { Blueprinter::V2::Serializer::Context }

  it 'should call formatters' do
    ext1 = Class.new(Blueprinter::V2::Extension) do
      format(Date) { |context| context.value.iso8601 }
    end
    ext2 = Class.new(Blueprinter::V2::Extension) do
      format TrueClass, :yes
      format FalseClass, :no

      def yes(_context)
        "Yes"
      end

      def no(_context)
        "No"
      end
    end

    formatter = described_class.new([ext1.new, ext2.new])
    expect(formatter.call(context.new(blueprint.new, field, Date.new(2024, 10, 1), object, {}))).to eq '2024-10-01'
    expect(formatter.call(context.new(blueprint.new, field, true, object, {}))).to eq "Yes"
    expect(formatter.call(context.new(blueprint.new, field, false, object, {}))).to eq "No"
    expect(formatter.call(context.new(blueprint.new, field, "foo", object, {}))).to eq "foo"
  end

  it 'should evaluate blocks against the extension instance' do
    ext = Class.new(Blueprinter::V2::Extension) do
      format(Date) { |context| str_date context.value }

      def str_date(date)
        date.iso8601
      end
    end

    formatter = described_class.new([ext.new])
    expect(formatter.call(context.new(blueprint.new, field, Date.new(2024, 10, 1), object, {}))).to eq '2024-10-01'
  end
end
