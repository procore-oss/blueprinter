# frozen_string_literal: true

describe Blueprinter::V2::FieldLogic do
  include ExtensionHelpers

  let(:subject) { described_class }
  let(:object) { { foo: 'Foo' } }
  let(:field) { blueprint.reflections[:default].fields[:foo] }

  context 'skip? (if)' do

    it 'allows by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      skip = subject.skip?(ctx, ctx.blueprint, field)
      expect(skip).to be false
    end

    it 'checks field options (Proc)' do
      blueprint.field :foo, if: ->(ctx) { ctx.object[ctx.field.from] == 'Foo' }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      skip = subject.skip?(ctx, ctx.blueprint, field)
      expect(skip).to be false

      object[:foo] = 'Bar'
      skip = subject.skip?(ctx, ctx.blueprint, field)
      expect(skip).to be true
    end

    it 'checks field options (Symbol)' do
      blueprint.field :foo, if: :foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      skip = subject.skip?(ctx, ctx.blueprint, field)
      expect(skip).to be false

      object[:foo] = 'Bar'
      skip = subject.skip?(ctx, ctx.blueprint, field)
      expect(skip).to be true
    end

    it 'checks blueprint options (Proc)' do
      blueprint.options[:if] = ->(ctx) { ctx.object[ctx.field.from] == 'Foo' }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      skip = subject.skip?(ctx, ctx.blueprint, field)
      expect(skip).to be false

      object[:foo] = 'Bar'
      skip = subject.skip?(ctx, ctx.blueprint, field)
      expect(skip).to be true
    end

    it 'checks blueprint options (Symbol)' do
      blueprint.options[:if] = :foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      skip = subject.skip?(ctx, ctx.blueprint, field)
      expect(skip).to be false

      object[:foo] = 'Bar'
      skip = subject.skip?(ctx, ctx.blueprint, field)
      expect(skip).to be true
    end

    it 'field options take priority over blueprint options' do
      blueprint.options[:if] = ->(_ctx) { false }
      blueprint.field :foo, if: :foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      skip = subject.skip?(ctx, ctx.blueprint, field)
      expect(skip).to be false

      object[:foo] = 'Bar'
      skip = subject.skip?(ctx, ctx.blueprint, field)
      expect(skip).to be true
    end
  end
end
