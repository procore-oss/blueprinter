# frozen_string_literal: true

require 'date'

describe Blueprinter::V2::Extension do
  subject { Class.new(described_class) }

  context 'format' do
    it 'should add a block formatter' do
      iso8601 = ->(x, _opts) { x.iso8601 }
      subject.format(Date, &iso8601)
      subject.format(Time, &iso8601)

      expect(subject.formatters[Date]).to eq iso8601
      expect(subject.formatters[Time]).to eq iso8601
    end

    it 'should add a method formatter' do
      subject.format(Date, :fmt_date)
      subject.format(Time, :fmt_time)

      expect(subject.formatters[Date]).to eq :fmt_date
      expect(subject.formatters[Time]).to eq :fmt_time
    end
  end

  context 'hooks' do
    let(:blueprint) { Class.new(Blueprinter::V2::Base) }
    let(:field) { Blueprinter::V2::Field.new(name: :foo, from: :foo) }
    let(:object) { { foo: 'Foo' } }
    let(:context) { Blueprinter::V2::Serializer::Context }

    it 'should default exclude_field? to false' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.exclude_field?(ctx)).to be false
    end

    it 'should default exclude_object? to false' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.exclude_object?(ctx)).to be false
    end

    it 'should default exclude_collection? to false' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.exclude_collection?(ctx)).to be false
    end

    it 'should default field_value to the given value' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.field_value(ctx)).to be 'Foo'
    end

    it 'should default object_value to the given value' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.object_value(ctx)).to be 'Foo'
    end

    it 'should default collection_value to the given value' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.new.collection_value(ctx)).to be 'Foo'
    end

    it 'should default input to the given object' do
      expect(subject.new.input(blueprint.new, object, {})).to eq object
    end

    it 'should default output to the given object' do
      expect(subject.new.output(blueprint.new, object, {})).to eq object
    end
  end
end
