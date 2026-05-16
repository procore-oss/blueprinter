# frozen_string_literal: true

describe Blueprinter::V2::FieldLogic do
  include ExtensionHelpers

  let(:subject) { blueprint.serializer }
  let(:object) { { foo: 'Foo' } }

  # This code now lives in Serializer for perf reasons, but the tests are here since it's still "field logic"
  context 'exclude_if_nil' do
    it 'allows by default' do
      res = subject.object(object, {}, instances:, store:, depth: 1)
      expect(res).to include(:foo)
    end

    it 'checks field options (true)' do
      blueprint.field :foo, exclude_if_nil: true
      res = subject.object(object, {}, instances:, store:, depth: 1)
      expect(res).to include(:foo)

      object[:foo] = nil
      res = subject.object(object, {}, instances:, store:, depth: 1)
      expect(res).to_not include(:foo)
    end

    it 'checks field options (false)' do
      blueprint.field :foo, exclude_if_nil: false
      res = subject.object(object, {}, instances:, store:, depth: 1)
      expect(res).to include(:foo)

      object[:foo] = nil
      res = subject.object(object, {}, instances:, store:, depth: 1)
      expect(res).to include(:foo)
    end

    it 'checks blueprint options (true)' do
      blueprint.options[:exclude_if_nil] = true
      res = subject.object(object, {}, instances:, store:, depth: 1)
      expect(res).to include(:foo)

      object[:foo] = nil
      res = subject.object(object, {}, instances:, store:, depth: 1)
      expect(res).to_not include(:foo)
    end

    it 'checks blueprint options (false)' do
      blueprint.options[:exclude_if_nil] = false
      res = subject.object(object, {}, instances:, store:, depth: 1)
      expect(res).to include(:foo)

      object[:foo] = nil
      res = subject.object(object, {}, instances:, store:, depth: 1)
      expect(res).to include(:foo)
    end

    it 'field options take priority over blueprint options' do
      blueprint.options[:exclude_if_nil] = true
      blueprint.field :foo, exclude_if_nil: false
      res = subject.object(object, {}, instances:, store:, depth: 1)
      expect(res).to include(:foo)

      object[:foo] = nil
      res = subject.object(object, {}, instances:, store:, depth: 1)
      expect(res).to include(:foo)
    end
  end
end
