# frozen_string_literal: true

describe Blueprinter::V2::FieldLogic do
  include ExtensionHelpers

  let(:subject) { described_class }

  context "value_or_default" do
    let(:field) { blueprint.reflections[:default].fields[:foo] }
    let(:object) { { foo: 'Foo' } }

    it 'passes values through by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.value_or_default(ctx, ctx.blueprint, field, 'Foo')
      expect(value).to eq 'Foo'
    end

    it 'passes values through by with defaults given' do
      blueprint.field :foo, default: 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.value_or_default(ctx, ctx.blueprint, field, 'Foo')
      expect(value).to eq 'Foo'
    end

    it 'passes values through with false default_ifs given' do
      blueprint.field :foo, default: 'Bar', default_if: ->(_, _) { false }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.value_or_default(ctx, ctx.blueprint, field, 'Foo')
      expect(value).to eq 'Foo'
    end

    it 'passes nil through by default' do
      object[:foo] = nil
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.value_or_default(ctx, ctx.blueprint, field, nil)
      expect(value).to be_nil
    end

    it 'uses field options default' do
      object[:foo] = nil
      blueprint.field :foo, default: 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.value_or_default(ctx, ctx.blueprint, field, nil)
      expect(value).to eq 'Bar'
    end

    it 'uses field options default (Proc)' do
      object[:foo] = nil
      blueprint.field :foo, default: ->(val, ctx) { "Bar (was #{val.inspect})"}
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.value_or_default(ctx, ctx.blueprint, field, nil)
      expect(value).to eq 'Bar (was nil)'
    end

    it 'uses field options default (Symbol)' do
      object[:foo] = nil
      blueprint.field :foo, default: :was
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.value_or_default(ctx, ctx.blueprint, field, nil)
      expect(value).to eq 'was nil'
    end

    it 'checks with field options default_if (Proc) (default = field options default)' do
      blueprint.field :foo, default: 'Bar', default_if: ->(val, _ctx) { is? val, 'Foo' }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.value_or_default(ctx, ctx.blueprint, field, 'Foo')
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = blueprint options default)' do
      blueprint.options[:default] = 'Bar'
      blueprint.field :foo, default_if: ->(val, _ctx) { is? val, 'Foo' }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.value_or_default(ctx, ctx.blueprint, field, 'Foo')
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options default_if (Proc) (default = field options default)' do
      blueprint.options[:default_if] = ->(val, _ctx) { is? val, 'Foo' }
      blueprint.field :foo, default: 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.value_or_default(ctx, ctx.blueprint, field, 'Foo')
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options default_if (Symbol) (default = blueprint options default)' do
      blueprint.options[:default] = 'Bar'
      blueprint.options[:default_if] = ->(val, _ctx) { is? val, 'Foo' }
      blueprint.field :foo
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.value_or_default(ctx, ctx.blueprint, field, 'Foo')
      expect(value).to eq 'Bar'
    end
  end
end
