# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Core::Postlude do
  subject { described_class.new }
  let(:context) { Blueprinter::V2::Context::Result }
  let(:object) { { 'name' => 'Foo' } }
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :name

      def meta_links
        { links: [] }
      end
    end
  end

  it 'passes through the result by default for objects' do
    ctx = context.new(blueprint.new, {}, object, { name: 'Foo' })
    result = subject.output_object(ctx)
    expect(result).to eq({ name: 'Foo' })
  end

  it 'passes through the result by default for collections' do
    ctx = context.new(blueprint.new, {}, object, [{ name: 'Foo' }])
    result = subject.output_collection(ctx)
    expect(result).to eq([{ name: 'Foo' }])
  end

  it 'looks for a root option in the blueprint for objects' do
    blueprint.options[:root] = :data
    ctx = context.new(blueprint.new, {}, object, { name: 'Foo' })
    result = subject.output_object(ctx)
    expect(result).to eq({ data: { name: 'Foo' } })
  end

  it 'looks for a root option in the blueprint for collections' do
    blueprint.options[:root] = :data
    ctx = context.new(blueprint.new, {}, object, [{ name: 'Foo' }])
    result = subject.output_collection(ctx)
    expect(result).to eq({ data: [{ name: 'Foo' }] })
  end

  it 'looks for a root option in the options over the blueprint' do
    blueprint.options[:root] = :data
    ctx = context.new(blueprint.new, { root: :root }, object, { name: 'Foo' })
    result = subject.output_object(ctx)
    expect(result).to eq({ root: { name: 'Foo' } })
  end

  it 'looks for a meta option in the blueprint' do
    blueprint.options[:root] = :data
    blueprint.options[:meta] = { links: [] }
    ctx = context.new(blueprint.new, {}, object, { name: 'Foo' })
    result = subject.output_object(ctx)
    expect(result).to eq({ data: { name: 'Foo' }, meta: { links: [] } })
  end

  it 'looks for a meta option in the options over the blueprint' do
    blueprint.options[:root] = :data
    blueprint.options[:meta] = { links: [] }
    ctx = context.new(blueprint.new, { root: :root, meta: { linkz: [] }}, object, { name: 'Foo' })
    result = subject.output_object(ctx)
    expect(result).to eq({ root: { name: 'Foo' }, meta: { linkz: [] } })
  end

  it 'looks for a meta Proc option in the blueprint' do
    blueprint.options[:root] = :data
    blueprint.options[:meta] = ->(ctx) { meta_links }
    ctx = context.new(blueprint.new, {}, object, { name: 'Foo' })
    result = subject.output_object(ctx)
    expect(result).to eq({ data: { name: 'Foo' }, meta: { links: [] } })
  end

  it 'looks for a meta Proc option in the options' do
    blueprint.options[:root] = :data
    ctx = context.new(blueprint.new, nil, { name: 'Foo' }, nil, )
    ctx = context.new(blueprint.new, { root: :root, meta: ->(ctx) { meta_links } }, object, { name: 'Foo' })
    result = subject.output_object(ctx)
    expect(result).to eq({ root: { name: 'Foo' }, meta: { links: [] } })
  end
end
