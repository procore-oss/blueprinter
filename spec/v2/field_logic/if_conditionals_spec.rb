# frozen_string_literal: true

describe Blueprinter::V2::FieldLogic do
  include ExtensionHelpers

  let(:subject) { described_class }
  let(:object) { { foo: 'Foo' } }
  let(:field_ref) { blueprint.reflections[:default].fields[:foo] }
  let(:field) { blueprint.schema.fetch(:foo) }
  let(:ctx) { prepare(blueprint, {}, Blueprinter::V2::Context::Field, blueprint.options, object, field_ref) }

  context 'skip? (if)' do
    it 'allows by default' do
      skip = subject.skip?(ctx, field)
      expect(skip).to be false
    end

    it 'checks field options (Proc)' do
      blueprint.field :foo, if: ->(ctx) { ctx.object[ctx.field.source] == 'Foo' }
      skip = subject.skip?(ctx, field)
      expect(skip).to be false

      object[:foo] = 'Bar'
      skip = subject.skip?(ctx, field)
      expect(skip).to be true
    end

    it 'checks field options (Symbol)' do
      blueprint.field :foo, if: :foo?
      skip = subject.skip?(ctx, field)
      expect(skip).to be false

      object[:foo] = 'Bar'
      skip = subject.skip?(ctx, field)
      expect(skip).to be true
    end

    it 'checks blueprint options (Proc)' do
      blueprint.options[:if] = ->(ctx) { ctx.object[ctx.field.source] == 'Foo' }
      skip = subject.skip?(ctx, field)
      expect(skip).to be false

      object[:foo] = 'Bar'
      skip = subject.skip?(ctx, field)
      expect(skip).to be true
    end

    it 'checks blueprint options (Symbol)' do
      blueprint.options[:if] = :foo?
      skip = subject.skip?(ctx, field)
      expect(skip).to be false

      object[:foo] = 'Bar'
      skip = subject.skip?(ctx, field)
      expect(skip).to be true
    end

    it 'field options take priority over blueprint options' do
      blueprint.options[:if] = ->(_ctx) { false }
      blueprint.field :foo, if: :foo?
      skip = subject.skip?(ctx, field)
      expect(skip).to be false

      object[:foo] = 'Bar'
      skip = subject.skip?(ctx, field)
      expect(skip).to be true
    end
  end
end
