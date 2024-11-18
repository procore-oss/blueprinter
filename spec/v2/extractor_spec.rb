# frozen_string_literal: true

describe Blueprinter::V2::Extractor do
  subject { described_class.new }
  let(:context) { Blueprinter::V2::Context }

  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      def upcase(str)
        str.upcase
      end
    end
  end

  context 'field' do
    it "should extract using a block" do
      field = Blueprinter::V2::Field.new(from: :foo, value_proc: ->(obj, _opts) { upcase obj[:foo] })
      ctx = context.new(blueprint.new, field, nil, { foo: 'bar' }, {})
      val = subject.field(ctx)
      expect(val).to eq 'BAR'
    end

    it "should extract using a Hash key" do
      field = Blueprinter::V2::Field.new(from: :foo)
      ctx = context.new(blueprint.new, field, nil, { foo: 'bar' }, {})
      val = subject.field(ctx)
      expect(val).to eq 'bar'
    end

    it "should extract using a method name" do
      field = Blueprinter::V2::Field.new(from: :name)
      obj = Struct.new(:name).new("Foo")
      ctx = context.new(blueprint.new, field, nil, obj, {})
      val = subject.field(ctx)
      expect(val).to eq 'Foo'
    end
  end

  context 'object' do
    it "should extract using a block" do
      field = Blueprinter::V2::ObjectField.new(from: :foo, value_proc: ->(obj, _opts) { upcase obj[:foo] })
      ctx = context.new(blueprint.new, field, nil, { foo: 'bar' }, {})
      val = subject.object(ctx)
      expect(val).to eq 'BAR'
    end

    it "should extract using a Hash key" do
      field = Blueprinter::V2::Field.new(from: :foo)
      ctx = context.new(blueprint.new, field, nil, { foo: 'bar' }, {})
      val = subject.object(ctx)
      expect(val).to eq 'bar'
    end

    it "should extract using a method name" do
      field = Blueprinter::V2::Field.new(from: :name)
      obj = Struct.new(:name).new("Foo")
      ctx = context.new(blueprint.new, field, nil, obj, {})
      val = subject.object(ctx)
      expect(val).to eq 'Foo'
    end
  end

  context 'collection' do
    it "should extract using a block" do
      field = Blueprinter::V2::Collection.new(from: :foo, value_proc: ->(obj, _opts) { upcase obj[:foo] })
      ctx = context.new(blueprint.new, field, nil, { foo: 'bar' }, {})
      val = subject.collection(ctx)
      expect(val).to eq 'BAR'
    end

    it "should extract using a Hash key" do
      field = Blueprinter::V2::Field.new(from: :foo)
      ctx = context.new(blueprint.new, field, nil, { foo: 'bar' }, {})
      val = subject.collection(ctx)
      expect(val).to eq 'bar'
    end

    it "should extract using a method name" do
      field = Blueprinter::V2::Field.new(from: :name)
      obj = Struct.new(:name).new("Foo")
      ctx = context.new(blueprint.new, field, nil, obj, {})
      val = subject.collection(ctx)
      expect(val).to eq 'Foo'
    end
  end
end
