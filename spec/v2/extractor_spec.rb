# frozen_string_literal: true

describe Blueprinter::Extractor do
  subject { described_class.new }
  let(:context) { Blueprinter::V2::Context::Field }
  let(:instances) { Blueprinter::V2::InstanceCache.new }

  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      def upcase(str)
        str.upcase
      end
    end
  end

  context 'field' do
    it "extracts using a Symbol Hash key" do
      field = Blueprinter::V2::Fields::Field.new(from: :foo, from_str: 'foo')
      ctx = context.new(blueprint.new, {}, instances, {}, { foo: 'bar' }, field, nil)
      val = subject.field(ctx)
      expect(val).to eq 'bar'
    end

    it "extracts using a String Hash key" do
      field = Blueprinter::V2::Fields::Field.new(from: :foo, from_str: 'foo')
      ctx = context.new(blueprint.new, {}, instances, {}, { 'foo' => 'bar' }, field, nil)
      val = subject.field(ctx)
      expect(val).to eq 'bar'
    end

    it "extracts using a method name" do
      field = Blueprinter::V2::Fields::Field.new(from: :name, from_str: 'name')
      obj = Struct.new(:name).new("Foo")
      ctx = context.new(blueprint.new, {}, instances, {}, obj, field, nil)
      val = subject.field(ctx)
      expect(val).to eq 'Foo'
    end
  end

  context 'object' do
    it "extracts using a Symbol Hash key" do
      field = Blueprinter::V2::Fields::Object.new(from: :foo, from_str: 'foo')
      ctx = context.new(blueprint.new, {}, instances, {}, { foo: 'bar' }, field, nil)
      val = subject.object(ctx)
      expect(val).to eq 'bar'
    end

    it "extracts using a String Hash key" do
      field = Blueprinter::V2::Fields::Object.new(from: :foo, from_str: 'foo')
      ctx = context.new(blueprint.new, {}, instances, {}, { 'foo' => 'bar' }, field, nil)
      val = subject.field(ctx)
      expect(val).to eq 'bar'
    end

    it "extracts using a method name" do
      field = Blueprinter::V2::Fields::Object.new(from: :name, from_str: 'name')
      obj = Struct.new(:name).new("Foo")
      ctx = context.new(blueprint.new, {}, instances, {}, obj, field, nil)
      val = subject.object(ctx)
      expect(val).to eq 'Foo'
    end
  end

  context 'collection' do
    it "extracts using a Symbol Hash key" do
      field = Blueprinter::V2::Fields::Collection.new(from: :foo, from_str: 'foo')
      ctx = context.new(blueprint.new, {}, instances, {}, { foo: 'bar' }, field, nil)
      val = subject.collection(ctx)
      expect(val).to eq 'bar'
    end

    it "extracts using a String Hash key" do
      field = Blueprinter::V2::Fields::Collection.new(from: :foo, from_str: 'foo')
      ctx = context.new(blueprint.new, {}, instances, {}, { 'foo' => 'bar' }, field, nil)
      val = subject.field(ctx)
      expect(val).to eq 'bar'
    end

    it "extracts using a method name" do
      field = Blueprinter::V2::Fields::Collection.new(from: :name, from_str: 'name')
      obj = Struct.new(:name).new("Foo")
      ctx = context.new(blueprint.new, {}, instances, {}, obj, field, nil)
      val = subject.collection(ctx)
      expect(val).to eq 'Foo'
    end
  end
end
