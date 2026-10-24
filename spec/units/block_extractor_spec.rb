# frozen_string_literal: true

require 'ostruct'
require 'blueprinter/extractors/block_extractor'
require 'blueprinter/field'

describe Blueprinter::BlockExtractor do
  let(:extractor) { described_class.new }
  let(:obj) { OpenStruct.new(first_name: 'Meg') }
  let(:local_options) { { view: :default, prefix: 'Ms.' } }

  def define_field(&block)
    Blueprinter::Field.new(:name, :name, extractor, Class.new(Blueprinter::Base), block:)
  end

  def extract(field)
    field.extract(obj, local_options)
  end

  context 'with a Symbol#to_proc block' do
    it 'calls the method on the object' do
      field = define_field(&:first_name)

      expect(extract(field)).to eq('Meg')
    end
  end

  context 'with a regular block' do
    it 'passes local_options as keywords' do
      field = define_field { |o, prefix:, **| "#{prefix} #{o.first_name}" }

      expect(extract(field)).to eq('Ms. Meg')
    end
  end

  context 'with a lambda block' do
    it 'passes local_options as keywords' do
      field = define_field(&->(o, prefix:, **) { "#{prefix} #{o.first_name}" })

      expect(extract(field)).to eq('Ms. Meg')
    end

    it 'passes local_options to a lambda with a rest parameter' do
      field = define_field(&->(o, *rest) { "#{rest.first[:prefix]} #{o.first_name}" })

      expect(extract(field)).to eq('Ms. Meg')
    end
  end

  context 'with a Method#to_proc block' do
    it 'passes local_options as keywords' do
      helper = Module.new do
        def self.greet(o, prefix:, **)
          "#{prefix} #{o.first_name}"
        end
      end
      field = define_field(&helper.method(:greet))

      expect(extract(field)).to eq('Ms. Meg')
    end
  end
end
