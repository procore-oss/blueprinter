# frozen_string_literal: true

describe Blueprinter::V2::FieldLogic do
  include ExtensionHelpers

  let(:subject) { described_class }

  context "value_or_default" do
    let(:field) { blueprint.schema.fetch(:foo) }
    let(:object) { { foo: 'Foo' } }
    let(:ctx) { prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field, {}) }

    it 'passes values through by default' do
      ctx
      value = subject.value_or_default(field, 'Foo')
      expect(value).to eq 'Foo'
    end

    it 'passes values through by with defaults given' do
      blueprint.field :foo, default: 'Bar'
      ctx
      value = subject.value_or_default(field, 'Foo')
      expect(value).to eq 'Foo'
    end

    it 'passes values through with false default_ifs given' do
      blueprint.field :foo, default: 'Bar', default_if: ->(_, _) { false }
      value = subject.value_or_default(field, 'Foo', ctx:)
      expect(value).to eq 'Foo'
    end

    it 'passes nil through by default' do
      object[:foo] = nil
      ctx
      value = subject.value_or_default(field, nil)
      expect(value).to be_nil
    end

    it 'uses field options default' do
      object[:foo] = nil
      blueprint.field :foo, default: 'Bar'
      value = subject.value_or_default(field, nil, ctx:)
      expect(value).to eq 'Bar'
    end

    it 'uses field options default (Proc)' do
      object[:foo] = nil
      blueprint.field :foo, default: ->(ctx) do
        was_val = ctx.object[ctx.field.source]
        "Bar (was #{was_val.inspect})"
      end
      value = subject.value_or_default(field, nil, ctx:)
      expect(value).to eq 'Bar (was nil)'
    end

    it 'uses field options default (Symbol)' do
      object[:foo] = nil
      blueprint.field :foo, default: :was
      value = subject.value_or_default(field, nil, ctx:)
      expect(value).to eq 'was nil'
    end

    it 'checks with field options default_if (Proc) (default = field options default)' do
      blueprint.field :foo, default: 'Bar', default_if: ->(_ctx, val) { val == 'Foo' }
      value = subject.value_or_default(field, 'Foo', ctx:)
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = blueprint options default)' do
      blueprint.options[:default] = 'Bar'
      blueprint.field :foo, default_if: ->(_ctx, val) { val == 'Foo' }
      value = subject.value_or_default(field, 'Foo', ctx:)
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options default_if (Proc) (default = field options default)' do
      blueprint.options[:default_if] = ->(_ctx, val) { val == 'Foo' }
      blueprint.field :foo, default: 'Bar'
      value = subject.value_or_default(field, 'Foo', ctx:)
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options default_if (Symbol) (default = blueprint options default)' do
      blueprint.options[:default] = 'Bar'
      blueprint.options[:default_if] = ->(_ctx, val) { val == 'Foo' }
      blueprint.field :foo
      value = subject.value_or_default(field, 'Foo', ctx:)
      expect(value).to eq 'Bar'
    end
  end
end
