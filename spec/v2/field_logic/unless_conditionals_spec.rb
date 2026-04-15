# frozen_string_literal: true

describe Blueprinter::V2::FieldLogic do
  include ExtensionHelpers

  let(:subject) { described_class }
  let(:object) { { foo: 'Foo' } }
  let(:field) { blueprint.reflections[:default].fields[:foo] }
  let(:ctx) { prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field) }

  context 'skip? (unless)' do
    it 'allows by default' do
      skip = subject.skip?(ctx)
      expect(skip).to be false
    end

    it 'checks field options (Proc)' do
      blueprint.field :foo, unless: ->(ctx) { ctx.object[ctx.field.from] == 'Foo' }
      skip = subject.skip?(ctx)
      expect(skip).to be true

      object[:foo] = 'Bar'
      skip = subject.skip?(ctx)
      expect(skip).to be false
    end

    it 'checks field options (Symbol)' do
      blueprint.field :foo, unless: :foo?
      skip = subject.skip?(ctx)
      expect(skip).to be true

      object[:foo] = 'Bar'
      skip = subject.skip?(ctx)
      expect(skip).to be false
    end

    it 'checks blueprint options (Proc)' do
      blueprint.options[:unless] = ->(ctx) { ctx.object[ctx.field.from] == 'Foo' }
      skip = subject.skip?(ctx)
      expect(skip).to be true

      object[:foo] = 'Bar'
      skip = subject.skip?(ctx)
      expect(skip).to be false
    end

    it 'checks blueprint options (Symbol)' do
      blueprint.options[:unless] = :foo?
      skip = subject.skip?(ctx)
      expect(skip).to be true

      object[:foo] = 'Bar'
      skip = subject.skip?(ctx)
      expect(skip).to be false
    end

    it 'field options take priority over blueprint options' do
      blueprint.options[:unless] = ->(_ctx) { false }
      blueprint.field :foo, unless: :foo?
      skip = subject.skip?(ctx)
      expect(skip).to be true

      object[:foo] = 'Bar'
      skip = subject.skip?(ctx)
      expect(skip).to be false
    end
  end
end
