# frozen_string_literal: true

require 'blueprinter/empty_types'

describe Blueprinter::Extensions::LegacyOptions do
  subject { described_class.new }
  let(:extractor) do
    Class.new do
      def extract(field_name, object, local_options, options)
        "Extracted: #{object[field_name]}"
      end
    end
  end

  let(:extractor2) do
    Class.new do
      def extract(field_name, object, local_options, options)
        "Xtracted: #{object[field_name]}"
      end
    end
  end

  let(:blueprint) do
    extractor = self.extractor
    extractor2 = self.extractor2
    Class.new(Blueprinter::V2::Base) do
      field :name
      field :desc, extractor: extractor

      view :with_extractor do
        set :extractor, extractor
        field :foo, extractor: extractor2
      end
    end
  end

  it 'respects the field option' do
    blueprint.add subject
    result = blueprint.render({ name: 'foo', desc: 'bar' }).to_hash
    expect(result).to eq({ name: 'foo', desc: 'Extracted: bar' })
  end

  it 'respects the blueprint option' do
    blueprint.add subject
    result = blueprint[:with_extractor].render({ name: 'foo', desc: 'bar', foo: 'asdf' }).to_hash
    expect(result).to eq({
      name: 'Extracted: foo',
      desc: 'Extracted: bar',
      foo: 'Xtracted: asdf'
    })
  end

  it 'accepts an extractor instance, like V1' do
    instance = extractor.new
    blueprint = Class.new(Blueprinter::V2::Base) { field :name }
    blueprint.field :name, extractor: instance
    blueprint.add subject
    expect(blueprint.render({ name: 'foo' }).to_hash).to eq({ name: 'Extracted: foo' })
  end

  it 'instantiates the extractor once per render, like V1' do
    counter = Class.new do
      def self.count = @count ||= 0
      def initialize = self.class.instance_variable_set(:@count, self.class.count + 1)
      def extract(field_name, object, _local_options, _options) = object[field_name]
    end
    blueprint = Class.new(Blueprinter::V2::Base) { field :name }
    blueprint.set :extractor, counter
    blueprint.add subject
    blueprint.render([{ name: 'a' }, { name: 'b' }, { name: 'c' }]).to_hash
    expect(counter.count).to eq 1
  end

  it "passes the field's block to the extractor, like V1" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      set :extractor, Blueprinter::AutoExtractor
      field :name
      field :computed do |object, _ctx|
        "Computed: #{object[:name]}"
      end
    end
    blueprint.add subject
    expect(blueprint.render({ name: 'foo' }).to_hash).to eq({ name: 'foo', computed: 'Computed: foo' })
  end
end
