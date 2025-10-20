# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Core::Json do
  subject { described_class.new }
  let(:context) { Blueprinter::V2::Context::Result }
  let(:object) { { name: 'Foo' } }
  let(:fields) { blueprint.reflections[:default].ordered }
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :name
    end
  end

  it 'outputs a Hash' do
    ctx = context.new(blueprint.new, [], {}, { 'name' => 'Foo' }, :hash)
    result = subject.around_result(ctx) { |ctx| ctx.object }
    expect(result).to eq ctx.object
  end

  it 'outputs json' do
    ctx = context.new(blueprint.new, [], {}, { 'name' => 'Foo' }, :json)
    result = subject.around_result(ctx) { |ctx| ctx.object }
    expect(result.value).to eq ctx.object.to_json
  end

  it 'raises an exception for an unsupported format' do
    ctx = context.new(blueprint.new, [], {}, { 'name' => 'Foo' }, :yaml)
    expect do
      subject.around_result(ctx) { |ctx| ctx.object }
    end.to raise_error(Blueprinter::BlueprinterError, 'Unrecognized serialization format `:yaml`')
  end
end
