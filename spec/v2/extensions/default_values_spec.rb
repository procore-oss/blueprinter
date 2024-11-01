# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Values do
  subject { described_class.new }
  let(:context) { Blueprinter::V2::Context }
  let(:instance_cache) { Blueprinter::V2::InstanceCache.new }
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      def was(ctx)
        "was #{ctx.value.inspect}"
      end

      def is?(ctx, val)
        ctx.value == val
      end

      def foo?(ctx)
        is? ctx, 'Foo'
      end
    end
  end
  let(:object) { { name: 'Foo' } }

  context 'fields' do
    let(:field) { Blueprinter::V2::Field.new(name: :name, from: :name, options: {}) }

    it 'should pass values through by default' do
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'Foo'
    end

    it 'should pass values through by with defaults given' do
      blueprint.options[:field_default] = 'Bar'
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, nil, object, { field_default: 'Bar' }, instance_cache)
      expect(subject.field_value ctx).to eq 'Foo'
    end

    it 'should pass values through with false default_ifs given' do
      blueprint.options[:field_default] = 'Bar'
      blueprint.options[:field_default_if] = ->(_) { false }
      field.options[:default] = 'Bar'
      field.options[:default_if] = ->(_) { false }
      ctx = context.new(blueprint.new, field, nil, object, { field_default: 'Bar', field_default_if: ->(_) { false } }, instance_cache)
      expect(subject.field_value ctx).to eq 'Foo'
    end

    it 'should pass nil through by default' do
      object[:name] = nil
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.field_value ctx).to be_nil
    end

    it 'should use options field_default' do
      object[:name] = nil
      ctx = context.new(blueprint.new, field, nil, object, { field_default: 'Bar' }, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should use options field_default (Proc)' do
      object[:name] = nil
      ctx = context.new(blueprint.new, field, nil, object, { field_default: ->(ctx) { "Bar (#{was ctx})"} }, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar (was nil)'
    end

    it 'should use options field_default (Symbol)' do
      object[:name] = nil
      ctx = context.new(blueprint.new, field, nil, object, { field_default: :was }, instance_cache)
      expect(subject.field_value ctx).to eq 'was nil'
    end

    it 'should use field options default' do
      object[:name] = nil
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should use field options default (Proc)' do
      object[:name] = nil
      field.options[:default] = ->(ctx) { "Bar (was #{ctx.value.inspect})"}
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar (was nil)'
    end

    it 'should use field options default (Symbol)' do
      object[:name] = nil
      field.options[:default] = :was
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'was nil'
      end

    it 'should use blueprint options field_default' do
      object[:name] = nil
      blueprint.options[:field_default] = 'Bar'
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should use blueprint options field_default (Proc)' do
      object[:name] = nil
      blueprint.options[:field_default] = ->(ctx) { "Bar (#{was ctx})" }
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar (was nil)'
    end

    it 'should use blueprint options field_default (Symbol)' do
      object[:name] = nil
      blueprint.options[:field_default] = :was
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'was nil'
    end

    it 'should check with options field_default_if (default = options field_default)' do
      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default: 'Bar', field_default_if: ->(ctx) { is? ctx, 'Foo' } }, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'

      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default: 'Bar', field_default_if: :foo? }, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should check with options field_default_if (default = field options default)' do
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default_if: ->(ctx) { is? ctx, 'Foo' } }, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'

      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default_if: :foo? }, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should check with options field_default_if (default = blueprint options field_default)' do
      blueprint.options[:field_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default_if: ->(ctx) { is? ctx, 'Foo' } }, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'

      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default_if: :foo? }, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = options field_default)' do
      field.options[:default_if] = ->(ctx) { is? ctx, 'Foo' }
      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default: 'Bar' }, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'

      field.options[:default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default: 'Bar' }, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = field options default)' do
      field.options[:default_if] = ->(ctx) { is? ctx, 'Foo' }
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'

      field.options[:default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = blueprint options field_default)' do
      field.options[:default_if] = ->(ctx) { is? ctx, 'Foo' }
      blueprint.options[:field_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'

      field.options[:default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options field_default_if (default = options field_default)' do
      blueprint.options[:field_default_if] = ->(ctx) { is? ctx, 'Foo' }
      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default: 'Bar' }, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'

      blueprint.options[:field_default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default: 'Bar' }, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options field_default_if (default = field options default)' do
      blueprint.options[:field_default_if] = ->(ctx) { is? ctx, 'Foo' }
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'

      blueprint.options[:field_default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options field_default_if (default = blueprint options field_default)' do
      blueprint.options[:field_default_if] = ->(ctx) { is? ctx, 'Foo' }
      blueprint.options[:field_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'

      blueprint.options[:field_default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.field_value ctx).to eq 'Bar'
    end
  end

  context 'objects' do
    let(:field) { Blueprinter::V2::ObjectField.new(name: :name, from: :name, options: {}) }

    it 'should pass values through by default' do
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.object_value ctx).to eq 'Foo'
    end

    it 'should pass values through by with defaults given' do
      blueprint.options[:object_default] = 'Bar'
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, nil, object, { object_default: 'Bar' }, instance_cache)
      expect(subject.object_value ctx).to eq 'Foo'
    end

    it 'should pass values through with false default_ifs given' do
      blueprint.options[:object_default] = 'Bar'
      blueprint.options[:object_default_if] = ->(_) { false }
      field.options[:default] = 'Bar'
      field.options[:default_if] = ->(_) { false }
      ctx = context.new(blueprint.new, field, nil, object, { object_default: 'Bar', object_default_if: ->(_) { false } }, instance_cache)
      expect(subject.object_value ctx).to eq 'Foo'
    end

    it 'should pass nil through by default' do
      object[:name] = nil
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.object_value ctx).to be_nil
    end

    it 'should use options object_default' do
      object[:name] = nil
      ctx = context.new(blueprint.new, field, nil, object, { object_default: 'Bar' }, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should use options object_default (Proc)' do
      object[:name] = nil
      ctx = context.new(blueprint.new, field, nil, object, { object_default: ->(ctx) { "Bar (#{was ctx})" } }, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar (was nil)'
    end

    it 'should use options object_default (Symbol)' do
      object[:name] = nil
      ctx = context.new(blueprint.new, field, nil, object, { object_default: :was }, instance_cache)
      expect(subject.object_value ctx).to eq 'was nil'
    end

    it 'should use field options default' do
      object[:name] = nil
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should use field options default (Proc)' do
      object[:name] = nil
      field.options[:default] = ->(ctx) { "Bar (was #{ctx.value.inspect})"}
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar (was nil)'
    end

    it 'should use field options default (Symbol)' do
      object[:name] = nil
      field.options[:default] = :was
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.object_value ctx).to eq 'was nil'
    end

    it 'should use blueprint options object_default' do
      object[:name] = nil
      blueprint.options[:object_default] = 'Bar'
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should use blueprint options object_default (Proc)' do
      object[:name] = nil
      blueprint.options[:object_default] = ->(ctx) { "Bar (#{was ctx})" }
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar (was nil)'
    end

    it 'should use blueprint options object_default (Symbol)' do
      object[:name] = nil
      blueprint.options[:object_default] = :was
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.object_value ctx).to eq 'was nil'
    end

    it 'should check with options object_default_if (default = options object_default)' do
      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default: 'Bar', object_default_if: ->(ctx) { is? ctx, 'Foo' } }, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'

      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default: 'Bar', object_default_if: :foo? }, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should check with options object_default_if (default = field options default)' do
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default_if: ->(ctx) { is? ctx, 'Foo' } }, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'

      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default_if: :foo? }, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should check with options object_default_if (default = blueprint options object_default)' do
      blueprint.options[:object_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default_if: ->(ctx) { is? ctx, 'Foo' } }, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'

      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default_if: :foo? }, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = options object_default)' do
      field.options[:default_if] = ->(ctx) { is? ctx, 'Foo' }
      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default: 'Bar' }, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'

      field.options[:default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default: 'Bar' }, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = field options default)' do
      field.options[:default_if] = ->(ctx) { is? ctx, 'Foo' }
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'

      field.options[:default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = blueprint options object_default)' do
      field.options[:default_if] = ->(ctx) { is? ctx, 'Foo' }
      blueprint.options[:object_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'

      field.options[:default_if] = :foo?
      blueprint.options[:object_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options object_default_if (default = options object_default)' do
      blueprint.options[:object_default_if] = ->(ctx) { is? ctx, 'Foo' }
      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default: 'Bar' }, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'

      blueprint.options[:object_default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default: 'Bar' }, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options object_default_if (default = field options default)' do
      blueprint.options[:object_default_if] = ->(ctx) { is? ctx, 'Foo' }
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'

      blueprint.options[:object_default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options object_default_if (default = blueprint options object_default)' do
      blueprint.options[:object_default_if] = ->(ctx) { is? ctx, 'Foo' }
      blueprint.options[:object_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'

      blueprint.options[:object_default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.object_value ctx).to eq 'Bar'
    end
  end

  context 'collections' do
    let(:field) { Blueprinter::V2::Collection.new(name: :name, from: :name, options: {}) }

    it 'should pass values through by default' do
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq 'Foo'
    end

    it 'should pass values through by with defaults given' do
      blueprint.options[:collection_default] = 'Bar'
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, nil, object, { collection_default: 'Bar' }, instance_cache)
      expect(subject.collection_value ctx).to eq 'Foo'
    end

    it 'should pass values through with false default_ifs given' do
      blueprint.options[:collection_default] = 'Bar'
      blueprint.options[:collection_default_if] = ->(_) { false }
      field.options[:default] = 'Bar'
      field.options[:default_if] = ->(_) { false }
      ctx = context.new(blueprint.new, field, nil, object, { collection_default: 'Bar', collection_default_if: ->(_) { false } }, instance_cache)
      expect(subject.collection_value ctx).to eq 'Foo'
    end

    it 'should pass nil through by default' do
      object[:name] = nil
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.collection_value ctx).to be_nil
    end

    it 'should use options collection_default' do
      object[:name] = nil
      ctx = context.new(blueprint.new, field, nil, object, { collection_default: 'Bar' }, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should use options collection_default (Proc)' do
      object[:name] = nil
      ctx = context.new(blueprint.new, field, nil, object, { collection_default: ->(ctx) { "Bar (#{was ctx})" } }, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar (was nil)'
    end

    it 'should use options collection_default (Symbol)' do
      object[:name] = nil
      ctx = context.new(blueprint.new, field, nil, object, { collection_default: :was }, instance_cache)
      expect(subject.collection_value ctx).to eq 'was nil'
    end

    it 'should use field options default' do
      object[:name] = nil
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should use field options default (Proc)' do
      object[:name] = nil
      field.options[:default] = ->(ctx) { "Bar (was #{ctx.value.inspect})"}
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar (was nil)'
    end

    it 'should use field options default (Symbol)' do
      object[:name] = nil
      field.options[:default] = :was
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq 'was nil'
    end

    it 'should use blueprint options collection_default' do
      object[:name] = nil
      blueprint.options[:collection_default] = 'Bar'
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should use blueprint options collection_default (Proc)' do
      object[:name] = nil
      blueprint.options[:collection_default] = ->(ctx) { "Bar (#{was ctx})" }
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar (was nil)'
    end

    it 'should use blueprint options collection_default (Symbol)' do
      object[:name] = nil
      blueprint.options[:collection_default] = :was
      ctx = context.new(blueprint.new, field, nil, object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq 'was nil'
    end

    it 'should check with options collection_default_if (default = options collection_default)' do
      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default: 'Bar', collection_default_if: ->(ctx) { is? ctx, 'Foo' } }, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'

      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default: 'Bar', collection_default_if: :foo? }, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should check with options collection_default_if (default = field options default)' do
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default_if: ->(ctx) { is? ctx, 'Foo' } }, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'

      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default_if: :foo? }, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should check with options collection_default_if (default = blueprint options collection_default)' do
      blueprint.options[:collection_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default_if: ->(ctx) { is? ctx, 'Foo' } }, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'

      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default_if: :foo? }, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = options collection_default)' do
      field.options[:default_if] = ->(ctx) { is? ctx, 'Foo' }
      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default: 'Bar' }, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'

      field.options[:default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default: 'Bar' }, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = field options default)' do
      field.options[:default_if] = ->(ctx) { is? ctx, 'Foo' }
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'

      field.options[:default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = blueprint options collection_default)' do
      field.options[:default_if] = ->(ctx) { is? ctx, 'Foo' }
      blueprint.options[:collection_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'

      field.options[:default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options collection_default_if (default = options collection_default)' do
      blueprint.options[:collection_default_if] = ->(ctx) { is? ctx, 'Foo' }
      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default: 'Bar' }, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'

      blueprint.options[:collection_default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default: 'Bar' }, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options collection_default_if (default = field options default)' do
      blueprint.options[:collection_default_if] = ->(ctx) { is? ctx, 'Foo' }
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'

      blueprint.options[:collection_default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options collection_default_if (default = blueprint options collection_default)' do
      blueprint.options[:collection_default_if] = ->(ctx) { is? ctx, 'Foo' }
      blueprint.options[:collection_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'

      blueprint.options[:collection_default_if] = :foo?
      ctx = context.new(blueprint.new, field, 'Foo', object, {}, instance_cache)
      expect(subject.collection_value ctx).to eq 'Bar'
    end
  end
end
