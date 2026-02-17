# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Core::Defaults do
  include ExtensionHelpers

  context 'fields' do
    let(:field) { blueprint.reflections[:default].fields[:foo] }
    let(:object) { { foo: 'Foo' } }

    it 'passes values through by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'
    end

    it 'passes values through by with defaults given' do
      blueprint.options[:field_default] = 'Bar'
      blueprint.field :foo, default: 'Bar'
      ctx = prepare(blueprint, { field_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'
    end

    it 'passes values through with false default_ifs given' do
      blueprint.options[:field_default] = 'Bar'
      blueprint.options[:field_default_if] = ->(_, _) { false }
      blueprint.field :foo, default: 'Bar', default_if: ->(_, _) { false }
      ctx = prepare(blueprint, { field_default: 'Bar', field_default_if: ->(_, _) { false } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'
    end

    it 'passes nil through by default' do
      object[:foo] = nil
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { nil }
      expect(value).to be_nil
    end

    it 'uses options field_default' do
      object[:foo] = nil
      ctx = prepare(blueprint, { field_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'uses options field_default (Proc)' do
      object[:foo] = nil
      ctx = prepare(blueprint, { field_default: ->(val, ctx) { "Bar (was #{val.inspect})"} }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { nil }
      expect(value).to eq 'Bar (was nil)'
    end

    it 'uses options field_default (Symbol)' do
      object[:foo] = nil
      ctx = prepare(blueprint, { field_default: :was }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { nil }
      expect(value).to eq 'was nil'
    end

    it 'uses field options default' do
      object[:foo] = nil
      blueprint.field :foo, default: 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'uses field options default (Proc)' do
      object[:foo] = nil
      blueprint.field :foo, default: ->(val, ctx) { "Bar (was #{val.inspect})"}
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { nil }
      expect(value).to eq 'Bar (was nil)'
    end

    it 'uses field options default (Symbol)' do
      object[:foo] = nil
      blueprint.field :foo, default: :was
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { nil }
      expect(value).to eq 'was nil'
    end

    it 'uses blueprint options field_default' do
      object[:foo] = nil
      blueprint.options[:field_default] = 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'uses blueprint options field_default (Proc)' do
      object[:foo] = nil
      blueprint.options[:field_default] = ->(val, ctx) { "Bar (was #{val.inspect})" }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { nil }
      expect(value).to eq 'Bar (was nil)'
    end

    it 'uses blueprint options field_default (Symbol)' do
      object[:foo] = nil
      blueprint.options[:field_default] = :was
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { nil }
      expect(value).to eq 'was nil'
    end

    it 'checks with options field_default_if (default = options field_default)' do
      ctx = prepare(blueprint, { field_default: 'Bar', field_default_if: ->(val, ctx) { is? val, 'Foo' } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { nil }
      expect(value).to eq 'Bar'

      ctx = prepare(blueprint, { field_default: 'Bar', field_default_if: :foo? }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with options field_default_if (default = field options default)' do
      blueprint.field :foo, default: 'Bar'
      ctx = prepare(blueprint, { field_default_if: ->(val, _ctx) { is? val, 'Foo' } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Bar'

      ctx = prepare(blueprint, { field_default_if: :foo? }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Bar'
    end

    it 'checks with options field_default_if (default = blueprint options field_default)' do
      blueprint.options[:field_default] = 'Bar'
      ctx = prepare(blueprint, { field_default_if: ->(val, _ctx) { is? val, 'Foo' } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Bar'

      ctx = prepare(blueprint, { field_default_if: :foo? }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = options field_default)' do
      blueprint.field :foo, default_if: ->(val, _ctx) { is? val, 'Foo' }
      ctx = prepare(blueprint, { field_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = options field_default)' do
      blueprint.field :foo, default_if: :foo?
      ctx = prepare(blueprint, { field_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = field options default)' do
      blueprint.field :foo, default: 'Bar', default_if: ->(val, _ctx) { is? val, 'Foo' }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = field options default)' do
      blueprint.field :foo, default: 'Bar', default_if: :foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = blueprint options field_default)' do
      blueprint.field :foo, default: 'Bar', default_if: ->(val, _ctx) { is? val, 'Foo' }
      blueprint.options[:field_default] = 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = blueprint options field_default)' do
      blueprint.field :foo, default: 'Bar', default_if: :foo?
      blueprint.options[:field_default] = 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options field_default_if (Proc) (default = options field_default)' do
      blueprint.options[:field_default_if] = ->(val, _ctx) { is? val, 'Foo' }
      ctx = prepare(blueprint, { field_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options field_default_if (Symbol) (default = options field_default)' do
      blueprint.options[:field_default_if] = :foo?
      ctx = prepare(blueprint, { field_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options field_default_if (Proc) (default = field options default)' do
      blueprint.options[:field_default_if] = ->(val, _ctx) { is? val, 'Foo' }
      blueprint.field :foo, default: 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options field_default_if (Symbol) (default = field options default)' do
      blueprint.options[:field_default_if] = :foo?
      blueprint.field :foo, default: 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options field_default_if (Proc) (default = blueprint options field_default)' do
      blueprint.options[:field_default_if] = ->(val, _ctx) { is? val, 'Foo' }
      blueprint.options[:field_default] = 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options field_default_if (Symbol) (default = blueprint options field_default)' do
      blueprint.options[:field_default_if] = :foo?
      blueprint.options[:field_default] = 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end
  end

  context 'objects' do
    let(:field) { blueprint.reflections[:default].objects[:foo_obj] }
    let(:object) { { foo_obj: 'Foo' } }

    it 'passes values through by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'
    end

    it 'passes values through by with defaults given' do
      blueprint.options[:object_default] = 'Bar'
      blueprint.association :foo_obj, sub_blueprint, default: 'Bar'
      ctx = prepare(blueprint, { object_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'
    end

    it 'passes values through with false default_ifs given' do
      blueprint.options[:object_default] = 'Bar'
      blueprint.options[:object_default_if] = ->(_, _) { false }
      blueprint.association :foo_obj, sub_blueprint, default: 'Bar', default_if: ->(_, _) { false }
      ctx = prepare(blueprint, { object_default: 'Bar', object_default_if: ->(_, _) { false } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'
    end

    it 'passes nil through by default' do
      object[:foo_obj] = nil
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to be_nil
    end

    it 'uses options object_default' do
      object[:foo_obj] = nil
      ctx = prepare(blueprint, { object_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'uses options object_default (Proc)' do
      object[:foo_obj] = nil
      ctx = prepare(blueprint, { object_default: ->(val, _ctx) { "Bar (was #{val.inspect})" } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar (was nil)'
    end

    it 'uses options object_default (Symbol)' do
      object[:foo_obj] = nil
      ctx = prepare(blueprint, { object_default: :was }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'was nil'
    end

    it 'uses field options default' do
      object[:foo_obj] = nil
      blueprint.association :foo_obj, sub_blueprint, default: 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'uses field options default (Proc)' do
      object[:foo_obj] = nil
      blueprint.association :foo_obj, sub_blueprint, default: ->(val, _ctx) { "Bar (was #{val.inspect})" }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar (was nil)'
    end

    it 'uses field options default (Symbol)' do
      object[:foo_obj] = nil
      blueprint.association :foo_obj, sub_blueprint, default: :was
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'was nil'
    end

    it 'uses blueprint options object_default' do
      object[:foo_obj] = nil
      blueprint.options[:object_default] = 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'uses blueprint options object_default (Proc)' do
      object[:foo_obj] = nil
      blueprint.options[:object_default] = ->(val, _ctx) { "Bar (was #{val.inspect})" }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar (was nil)'
    end

    it 'uses blueprint options object_default (Symbol)' do
      object[:foo_obj] = nil
      blueprint.options[:object_default] = :was
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'was nil'
    end

    it 'checks with options object_default_if (default = options object_default)' do
      ctx = prepare(blueprint, { object_default: 'Bar', object_default_if: ->(val, _ctx) { is? val, 'Foo' } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'

      ctx = prepare(blueprint, { object_default: 'Bar', object_default_if: :foo? }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with options object_default_if (default = field options default)' do
      blueprint.association :foo_obj, sub_blueprint, default: 'Bar'
      ctx = prepare(blueprint, { object_default_if: ->(val, _ctx) { is? val, 'Foo' } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'

      ctx = prepare(blueprint, { object_default_if: :foo? }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with options object_default_if (default = blueprint options object_default)' do
      blueprint.options[:object_default] = 'Bar'
      ctx = prepare(blueprint, { object_default_if: ->(val, _ctx) { is? val, 'Foo' } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'

      ctx = prepare(blueprint, { object_default_if: :foo? }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = options object_default)' do
      blueprint.association :foo_obj, sub_blueprint, default_if: ->(val, _ctx) { is? val, 'Foo' }
      ctx = prepare(blueprint, { object_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = options object_default)' do
      blueprint.association :foo_obj, sub_blueprint, default_if: :foo?
      ctx = prepare(blueprint, { object_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = field options default)' do
      blueprint.association :foo_obj, sub_blueprint, default: 'Bar', default_if: ->(val, _ctx) { is? val, 'Foo' }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = field options default)' do
      blueprint.association :foo_obj, sub_blueprint, default: 'Bar', default_if: :foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = blueprint options object_default)' do
      blueprint.association :foo_obj, sub_blueprint, default_if: ->(val, _ctx) { is? val, 'Foo' }
      blueprint.options[:object_default] = 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = blueprint options object_default)' do
      blueprint.association :foo_obj, sub_blueprint, default_if: :foo?
      blueprint.options[:object_default] = 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options object_default_if (Proc) (default = options object_default)' do
      blueprint.options[:object_default_if] = ->(val, _ctx) { is? val, 'Foo' }
      ctx = prepare(blueprint, { object_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options object_default_if (Symbol) (default = options object_default)' do
      blueprint.options[:object_default_if] = :foo?
      ctx = prepare(blueprint, { object_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options object_default_if (Proc) (default = field options default)' do
      blueprint.options[:object_default_if] = ->(val, _ctx) { is? val, 'Foo' }
      blueprint.association :foo_obj, sub_blueprint, default: 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options object_default_if (Symbol) (default = field options default)' do
      blueprint.options[:object_default_if] = :foo?
      blueprint.association :foo_obj, sub_blueprint, default: 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options object_default_if (Proc) (default = blueprint options object_default)' do
      blueprint.options[:object_default_if] = ->(val, ctx) { is? val, 'Foo' }
      blueprint.options[:object_default] = 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options object_default_if (Symbol) (default = blueprint options object_default)' do
      blueprint.options[:object_default_if] = :foo?
      blueprint.options[:object_default] = 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end
  end

  context 'collections' do
    let(:field) { blueprint.reflections[:default].collections[:foos] }
    let(:object) { { foos: 'Foo' } }

    it 'passes values through by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'
    end

    it 'passes values through by with defaults given' do
      blueprint.options[:collection_default] = 'Bar'
      blueprint.association :foos, [sub_blueprint], default: 'Bar'
      ctx = prepare(blueprint, { collection_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'
    end

    it 'passes values through with false default_ifs given' do
      blueprint.options[:collection_default] = 'Bar'
      blueprint.options[:collection_default_if] = ->(_, _) { false }
      blueprint.association :foos, [sub_blueprint], default: 'Bar', default_if: ->(_, _) { false }
      ctx = prepare(blueprint, { collection_default: 'Bar', collection_default_if: ->_, (_) { false } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'
    end

    it 'passes nil through by default' do
      object[:foos] = nil
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to be_nil
    end

    it 'uses options collection_default' do
      object[:foos] = nil
      ctx = prepare(blueprint, { collection_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'uses options collection_default (Proc)' do
      object[:foos] = nil
      ctx = prepare(blueprint, { collection_default: ->(val, _ctx) { "Bar (was #{val.inspect})" } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar (was nil)'
    end

    it 'uses options collection_default (Symbol)' do
      object[:foos] = nil
      ctx = prepare(blueprint, { collection_default: :was }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'was nil'
    end

    it 'uses field options default' do
      object[:foos] = nil
      blueprint.association :foos, [sub_blueprint], default: 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'uses field options default (Proc)' do
      object[:foos] = nil
      blueprint.association :foos, [sub_blueprint], default: ->(val, _ctx) { "Bar (was #{val.inspect})"}
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar (was nil)'
    end

    it 'uses field options default (Symbol)' do
      object[:foos] = nil
      blueprint.association :foos, [sub_blueprint], default: :was
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'was nil'
    end

    it 'uses blueprint options collection_default' do
      object[:foos] = nil
      blueprint.options[:collection_default] = 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'uses blueprint options collection_default (Proc)' do
      object[:foos] = nil
      blueprint.options[:collection_default] = ->(val, _ctx) { "Bar (was #{val.inspect})" }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar (was nil)'
    end

    it 'uses blueprint options collection_default (Symbol)' do
      object[:foos] = nil
      blueprint.options[:collection_default] = :was
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'was nil'
    end

    it 'checks with options collection_default_if (default = options collection_default)' do
      ctx = prepare(blueprint, { collection_default: 'Bar', collection_default_if: ->(val, _ctx) { is? val, 'Foo' } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'

      ctx = prepare(blueprint, { collection_default: 'Bar', collection_default_if: :foo? }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with options collection_default_if (default = field options default)' do
      blueprint.association :foos, [sub_blueprint], default: 'Bar'
      ctx = prepare(blueprint, { collection_default_if: ->(val, _ctx) { is? val, 'Foo' } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'

      ctx = prepare(blueprint, { collection_default_if: :foo? }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with options collection_default_if (default = blueprint options collection_default)' do
      blueprint.options[:collection_default] = 'Bar'
      ctx = prepare(blueprint, { collection_default_if: ->(val, _ctx) { is? val, 'Foo' } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'

      ctx = prepare(blueprint, { collection_default_if: :foo? }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = options collection_default)' do
      blueprint.association :foos, [sub_blueprint], default_if: ->(val, _ctx) { is? val, 'Foo' }
      ctx = prepare(blueprint, { collection_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = options collection_default)' do
      blueprint.association :foos, [sub_blueprint], default_if: :foo?
      ctx = prepare(blueprint, { collection_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = field options default)' do
      blueprint.association :foos, [sub_blueprint], default_if: ->(val, _ctx) { is? val, 'Foo' }, default: 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = field options default)' do
      blueprint.association :foos, [sub_blueprint], default_if: :foo?, default: 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = blueprint options collection_default)' do
      blueprint.association :foos, [sub_blueprint], default_if: ->(val, _ctx) { is? val, 'Foo' }
      blueprint.options[:collection_default] = 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = blueprint options collection_default)' do
      blueprint.association :foos, [sub_blueprint], default_if: :foo?
      blueprint.options[:collection_default] = 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options collection_default_if (Proc) (default = options collection_default)' do
      blueprint.options[:collection_default_if] = ->(val, _ctx) { is? val, 'Foo' }
      ctx = prepare(blueprint, { collection_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options collection_default_if (Symbol) (default = options collection_default)' do
      blueprint.options[:collection_default_if] = :foo?
      ctx = prepare(blueprint, { collection_default: 'Bar' }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options collection_default_if (Proc) (default = field options default)' do
      blueprint.options[:collection_default_if] = ->(val, _ctx) { is? val, 'Foo' }
      blueprint.association :foos, [sub_blueprint], default: 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options collection_default_if (Symbol) (default = field options default)' do
      blueprint.options[:collection_default_if] = :foo?
      blueprint.association :foos, [sub_blueprint], default: 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options collection_default_if (Proc) (default = blueprint options collection_default)' do
      blueprint.options[:collection_default_if] = ->(val, _ctx) { is? val, 'Foo' }
      blueprint.options[:collection_default] = 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end

    it 'checks with blueprint options collection_default_if (Symbol) (default = blueprint options collection_default)' do
      blueprint.options[:collection_default_if] = :foo?
      blueprint.options[:collection_default] = 'Bar'
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { nil }
      expect(value).to eq 'Bar'
    end
  end
end
