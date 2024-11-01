# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Core::Values do
  include ExtensionHelpers

  context 'fields' do
    let(:field) { blueprint.reflections[:default].fields[:foo] }
    let(:object) { { foo: 'Foo' } }

    it 'passes values through by default' do
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'Foo'
    end

    it 'passes values through by with defaults given' do
      blueprint.options[:field_default] = 'Bar'
      blueprint.field :foo, default: 'Bar'
      ctx = prepare(blueprint, field, 'Foo', object, { field_default: 'Bar' })
      expect(subject.field_value ctx).to eq 'Foo'
    end

    it 'passes values through with false default_ifs given' do
      blueprint.options[:field_default] = 'Bar'
      blueprint.options[:field_default_if] = ->(_) { false }
      blueprint.field :foo, default: 'Bar', default_if: ->(_) { false }
      ctx = prepare(blueprint, field, nil, object, { field_default: 'Bar', field_default_if: ->(_) { false } })
      expect(subject.field_value ctx).to eq 'Foo'
    end

    it 'passes nil through by default' do
      object[:foo] = nil
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.field_value ctx).to be_nil
    end

    it 'uses options field_default' do
      object[:foo] = nil
      ctx = prepare(blueprint, field, nil, object, { field_default: 'Bar' })
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'uses options field_default (Proc)' do
      object[:foo] = nil
      ctx = prepare(blueprint, field, nil, object, { field_default: ->(ctx) { "Bar (#{was ctx})"} })
      expect(subject.field_value ctx).to eq 'Bar (was nil)'
    end

    it 'uses options field_default (Symbol)' do
      object[:foo] = nil
      ctx = prepare(blueprint, field, nil, object, { field_default: :was })
      expect(subject.field_value ctx).to eq 'was nil'
    end

    it 'uses field options default' do
      object[:foo] = nil
      blueprint.field :foo, default: 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'uses field options default (Proc)' do
      object[:foo] = nil
      blueprint.field :foo, default: ->(ctx) { "Bar (was #{ctx.value.inspect})"}
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'Bar (was nil)'
    end

    it 'uses field options default (Symbol)' do
      object[:foo] = nil
      blueprint.field :foo, default: :was
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'was nil'
    end

    it 'uses blueprint options field_default' do
      object[:foo] = nil
      blueprint.options[:field_default] = 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'uses blueprint options field_default (Proc)' do
      object[:foo] = nil
      blueprint.options[:field_default] = ->(ctx) { "Bar (#{was ctx})" }
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'Bar (was nil)'
    end

    it 'uses blueprint options field_default (Symbol)' do
      object[:foo] = nil
      blueprint.options[:field_default] = :was
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'was nil'
    end

    it 'checks with options field_default_if (default = options field_default)' do
      ctx = prepare(blueprint, field, nil, object, { field_default: 'Bar', field_default_if: ->(ctx) { is? ctx, 'Foo' } })
      expect(subject.field_value ctx).to eq 'Bar'

      ctx = prepare(blueprint, field, nil, object, { field_default: 'Bar', field_default_if: :foo? })
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'checks with options field_default_if (default = field options default)' do
      blueprint.field :foo, default: 'Bar'
      ctx = prepare(blueprint, field, 'Foo', object, { field_default_if: ->(ctx) { is? ctx, 'Foo' } })
      expect(subject.field_value ctx).to eq 'Bar'

      ctx = prepare(blueprint, field, 'Foo', object, { field_default_if: :foo? })
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'checks with options field_default_if (default = blueprint options field_default)' do
      blueprint.options[:field_default] = 'Bar'
      ctx = prepare(blueprint, field, 'Foo', object, { field_default_if: ->(ctx) { is? ctx, 'Foo' } })
      expect(subject.field_value ctx).to eq 'Bar'

      ctx = prepare(blueprint, field, 'Foo', object, { field_default_if: :foo? })
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = options field_default)' do
      blueprint.field :foo, default_if: ->(ctx) { is? ctx, 'Foo' }
      ctx = prepare(blueprint, field, 'Foo', object, { field_default: 'Bar' })
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = options field_default)' do
      blueprint.field :foo, default_if: :foo?
      ctx = prepare(blueprint, field, 'Foo', object, { field_default: 'Bar' })
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = field options default)' do
      blueprint.field :foo, default: 'Bar', default_if: ->(ctx) { is? ctx, 'Foo' }
      ctx = prepare(blueprint, field, 'Foo', object, {})
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = field options default)' do
      blueprint.field :foo, default: 'Bar', default_if: :foo?
      ctx = prepare(blueprint, field, 'Foo', object, {})
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = blueprint options field_default)' do
      blueprint.field :foo, default: 'Bar', default_if: ->(ctx) { is? ctx, 'Foo' }
      blueprint.options[:field_default] = 'Bar'
      ctx = prepare(blueprint, field, 'Foo', object, {})
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = blueprint options field_default)' do
      blueprint.field :foo, default: 'Bar', default_if: :foo?
      blueprint.options[:field_default] = 'Bar'
      ctx = prepare(blueprint, field, 'Foo', object, {})
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options field_default_if (Proc) (default = options field_default)' do
      blueprint.options[:field_default_if] = ->(ctx) { is? ctx, 'Foo' }
      ctx = prepare(blueprint, field, 'Foo', object, { field_default: 'Bar' })
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options field_default_if (Symbol) (default = options field_default)' do
      blueprint.options[:field_default_if] = :foo?
      ctx = prepare(blueprint, field, 'Foo', object, { field_default: 'Bar' })
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options field_default_if (Proc) (default = field options default)' do
      blueprint.options[:field_default_if] = ->(ctx) { is? ctx, 'Foo' }
      blueprint.field :foo, default: 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options field_default_if (Symbol) (default = field options default)' do
      blueprint.options[:field_default_if] = :foo?
      blueprint.field :foo, default: 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options field_default_if (Proc) (default = blueprint options field_default)' do
      blueprint.options[:field_default_if] = ->(ctx) { is? ctx, 'Foo' }
      blueprint.options[:field_default] = 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options field_default_if (Symbol) (default = blueprint options field_default)' do
      blueprint.options[:field_default_if] = :foo?
      blueprint.options[:field_default] = 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'Bar'
    end
  end

  context 'objects' do
    let(:field) { blueprint.reflections[:default].objects[:foo_obj] }
    let(:object) { { foo_obj: 'Foo' } }

    it 'passes values through by default' do
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Foo'
    end

    it 'passes values through by with defaults given' do
      blueprint.options[:object_default] = 'Bar'
      blueprint.object :foo_obj, sub_blueprint, default: 'Bar'
      ctx = prepare(blueprint, field, nil, object, { object_default: 'Bar' })
      expect(subject.object_value ctx).to eq 'Foo'
    end

    it 'passes values through with false default_ifs given' do
      blueprint.options[:object_default] = 'Bar'
      blueprint.options[:object_default_if] = ->(_) { false }
      blueprint.object :foo_obj, sub_blueprint, default: 'Bar', default_if: ->(_) { false }
      ctx = prepare(blueprint, field, nil, object, { object_default: 'Bar', object_default_if: ->(_) { false } })
      expect(subject.object_value ctx).to eq 'Foo'
    end

    it 'passes nil through by default' do
      object[:foo_obj] = nil
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to be_nil
    end

    it 'uses options object_default' do
      object[:foo_obj] = nil
      ctx = prepare(blueprint, field, nil, object, { object_default: 'Bar' })
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'uses options object_default (Proc)' do
      object[:foo_obj] = nil
      ctx = prepare(blueprint, field, nil, object, { object_default: ->(ctx) { "Bar (#{was ctx})" } })
      expect(subject.object_value ctx).to eq 'Bar (was nil)'
    end

    it 'uses options object_default (Symbol)' do
      object[:foo_obj] = nil
      ctx = prepare(blueprint, field, nil, object, { object_default: :was })
      expect(subject.object_value ctx).to eq 'was nil'
    end

    it 'uses field options default' do
      object[:foo_obj] = nil
      blueprint.object :foo_obj, sub_blueprint, default: 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'uses field options default (Proc)' do
      object[:foo_obj] = nil
      blueprint.object :foo_obj, sub_blueprint, default: ->(ctx) { "Bar (was #{ctx.value.inspect})" }
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Bar (was nil)'
    end

    it 'uses field options default (Symbol)' do
      object[:foo_obj] = nil
      blueprint.object :foo_obj, sub_blueprint, default: :was
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'was nil'
    end

    it 'uses blueprint options object_default' do
      object[:foo_obj] = nil
      blueprint.options[:object_default] = 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'uses blueprint options object_default (Proc)' do
      object[:foo_obj] = nil
      blueprint.options[:object_default] = ->(ctx) { "Bar (#{was ctx})" }
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Bar (was nil)'
    end

    it 'uses blueprint options object_default (Symbol)' do
      object[:foo_obj] = nil
      blueprint.options[:object_default] = :was
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'was nil'
    end

    it 'checks with options object_default_if (default = options object_default)' do
      ctx = prepare(blueprint, field, nil, object, { object_default: 'Bar', object_default_if: ->(ctx) { is? ctx, 'Foo' } })
      expect(subject.object_value ctx).to eq 'Bar'

      ctx = prepare(blueprint, field, nil, object, { object_default: 'Bar', object_default_if: :foo? })
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'checks with options object_default_if (default = field options default)' do
      blueprint.object :foo_obj, sub_blueprint, default: 'Bar'
      ctx = prepare(blueprint, field, nil, object, { object_default_if: ->(ctx) { is? ctx, 'Foo' } })
      expect(subject.object_value ctx).to eq 'Bar'

      ctx = prepare(blueprint, field, nil, object, { object_default_if: :foo? })
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'checks with options object_default_if (default = blueprint options object_default)' do
      blueprint.options[:object_default] = 'Bar'
      ctx = prepare(blueprint, field, nil, object, { object_default_if: ->(ctx) { is? ctx, 'Foo' } })
      expect(subject.object_value ctx).to eq 'Bar'

      ctx = prepare(blueprint, field, nil, object, { object_default_if: :foo? })
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = options object_default)' do
      blueprint.object :foo_obj, sub_blueprint, default_if: ->(ctx) { is? ctx, 'Foo' }
      ctx = prepare(blueprint, field, nil, object, { object_default: 'Bar' })
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = options object_default)' do
      blueprint.object :foo_obj, sub_blueprint, default_if: :foo?
      ctx = prepare(blueprint, field, nil, object, { object_default: 'Bar' })
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = field options default)' do
      blueprint.object :foo_obj, sub_blueprint, default: 'Bar', default_if: ->(ctx) { is? ctx, 'Foo' }
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = field options default)' do
      blueprint.object :foo_obj, sub_blueprint, default: 'Bar', default_if: :foo?
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = blueprint options object_default)' do
      blueprint.object :foo_obj, sub_blueprint, default_if: ->(ctx) { is? ctx, 'Foo' }
      blueprint.options[:object_default] = 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = blueprint options object_default)' do
      blueprint.object :foo_obj, sub_blueprint, default_if: :foo?
      blueprint.options[:object_default] = 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options object_default_if (Proc) (default = options object_default)' do
      blueprint.options[:object_default_if] = ->(ctx) { is? ctx, 'Foo' }
      ctx = prepare(blueprint, field, nil, object, { object_default: 'Bar' })
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options object_default_if (Symbol) (default = options object_default)' do
      blueprint.options[:object_default_if] = :foo?
      ctx = prepare(blueprint, field, nil, object, { object_default: 'Bar' })
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options object_default_if (Proc) (default = field options default)' do
      blueprint.options[:object_default_if] = ->(ctx) { is? ctx, 'Foo' }
      blueprint.object :foo_obj, sub_blueprint, default: 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options object_default_if (Symbol) (default = field options default)' do
      blueprint.options[:object_default_if] = :foo?
      blueprint.object :foo_obj, sub_blueprint, default: 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options object_default_if (Proc) (default = blueprint options object_default)' do
      blueprint.options[:object_default_if] = ->(ctx) { is? ctx, 'Foo' }
      blueprint.options[:object_default] = 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options object_default_if (Symbol) (default = blueprint options object_default)' do
      blueprint.options[:object_default_if] = :foo?
      blueprint.options[:object_default] = 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Bar'
    end
  end

  context 'collections' do
    let(:field) { blueprint.reflections[:default].collections[:foos] }
    let(:object) { { foos: 'Foo' } }

    it 'passes values through by default' do
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Foo'
    end

    it 'passes values through by with defaults given' do
      blueprint.options[:collection_default] = 'Bar'
      blueprint.collection :foos, sub_blueprint, default: 'Bar'
      ctx = prepare(blueprint, field, nil, object, { collection_default: 'Bar' })
      expect(subject.collection_value ctx).to eq 'Foo'
    end

    it 'passes values through with false default_ifs given' do
      blueprint.options[:collection_default] = 'Bar'
      blueprint.options[:collection_default_if] = ->(_) { false }
      blueprint.collection :foos, sub_blueprint, default: 'Bar', default_if: ->(_) { false }
      ctx = prepare(blueprint, field, nil, object, { collection_default: 'Bar', collection_default_if: ->(_) { false } })
      expect(subject.collection_value ctx).to eq 'Foo'
    end

    it 'passes nil through by default' do
      object[:foos] = nil
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to be_nil
    end

    it 'uses options collection_default' do
      object[:foos] = nil
      ctx = prepare(blueprint, field, nil, object, { collection_default: 'Bar' })
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'uses options collection_default (Proc)' do
      object[:foos] = nil
      ctx = prepare(blueprint, field, nil, object, { collection_default: ->(ctx) { "Bar (#{was ctx})" } })
      expect(subject.collection_value ctx).to eq 'Bar (was nil)'
    end

    it 'uses options collection_default (Symbol)' do
      object[:foos] = nil
      ctx = prepare(blueprint, field, nil, object, { collection_default: :was })
      expect(subject.collection_value ctx).to eq 'was nil'
    end

    it 'uses field options default' do
      object[:foos] = nil
      blueprint.collection :foos, sub_blueprint, default: 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'uses field options default (Proc)' do
      object[:foos] = nil
      blueprint.collection :foos, sub_blueprint, default: ->(ctx) { "Bar (was #{ctx.value.inspect})"}
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Bar (was nil)'
    end

    it 'uses field options default (Symbol)' do
      object[:foos] = nil
      blueprint.collection :foos, sub_blueprint, default: :was
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'was nil'
    end

    it 'uses blueprint options collection_default' do
      object[:foos] = nil
      blueprint.options[:collection_default] = 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'uses blueprint options collection_default (Proc)' do
      object[:foos] = nil
      blueprint.options[:collection_default] = ->(ctx) { "Bar (#{was ctx})" }
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Bar (was nil)'
    end

    it 'uses blueprint options collection_default (Symbol)' do
      object[:foos] = nil
      blueprint.options[:collection_default] = :was
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'was nil'
    end

    it 'checks with options collection_default_if (default = options collection_default)' do
      ctx = prepare(blueprint, field, nil, object, { collection_default: 'Bar', collection_default_if: ->(ctx) { is? ctx, 'Foo' } })
      expect(subject.collection_value ctx).to eq 'Bar'

      ctx = prepare(blueprint, field, nil, object, { collection_default: 'Bar', collection_default_if: :foo? })
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'checks with options collection_default_if (default = field options default)' do
      blueprint.collection :foos, sub_blueprint, default: 'Bar'
      ctx = prepare(blueprint, field, nil, object, { collection_default_if: ->(ctx) { is? ctx, 'Foo' } })
      expect(subject.collection_value ctx).to eq 'Bar'

      ctx = prepare(blueprint, field, nil, object, { collection_default_if: :foo? })
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'checks with options collection_default_if (default = blueprint options collection_default)' do
      blueprint.options[:collection_default] = 'Bar'
      ctx = prepare(blueprint, field, nil, object, { collection_default_if: ->(ctx) { is? ctx, 'Foo' } })
      expect(subject.collection_value ctx).to eq 'Bar'

      ctx = prepare(blueprint, field, nil, object, { collection_default_if: :foo? })
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = options collection_default)' do
      blueprint.collection :foos, sub_blueprint, default_if: ->(ctx) { is? ctx, 'Foo' }
      ctx = prepare(blueprint, field, nil, object, { collection_default: 'Bar' })
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = options collection_default)' do
      blueprint.collection :foos, sub_blueprint, default_if: :foo?
      ctx = prepare(blueprint, field, nil, object, { collection_default: 'Bar' })
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = field options default)' do
      blueprint.collection :foos, sub_blueprint, default_if: ->(ctx) { is? ctx, 'Foo' }, default: 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = field options default)' do
      blueprint.collection :foos, sub_blueprint, default_if: :foo?, default: 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Proc) (default = blueprint options collection_default)' do
      blueprint.collection :foos, sub_blueprint, default_if: ->(ctx) { is? ctx, 'Foo' }
      blueprint.options[:collection_default] = 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'checks with field options default_if (Symbol) (default = blueprint options collection_default)' do
      blueprint.collection :foos, sub_blueprint, default_if: :foo?
      blueprint.options[:collection_default] = 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options collection_default_if (Proc) (default = options collection_default)' do
      blueprint.options[:collection_default_if] = ->(ctx) { is? ctx, 'Foo' }
      ctx = prepare(blueprint, field, nil, object, { collection_default: 'Bar' })
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options collection_default_if (Symbol) (default = options collection_default)' do
      blueprint.options[:collection_default_if] = :foo?
      ctx = prepare(blueprint, field, nil, object, { collection_default: 'Bar' })
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options collection_default_if (Proc) (default = field options default)' do
      blueprint.options[:collection_default_if] = ->(ctx) { is? ctx, 'Foo' }
      blueprint.collection :foos, sub_blueprint, default: 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options collection_default_if (Symbol) (default = field options default)' do
      blueprint.options[:collection_default_if] = :foo?
      blueprint.collection :foos, sub_blueprint, default: 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options collection_default_if (Proc) (default = blueprint options collection_default)' do
      blueprint.options[:collection_default_if] = ->(ctx) { is? ctx, 'Foo' }
      blueprint.options[:collection_default] = 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'checks with blueprint options collection_default_if (Symbol) (default = blueprint options collection_default)' do
      blueprint.options[:collection_default_if] = :foo?
      blueprint.options[:collection_default] = 'Bar'
      ctx = prepare(blueprint, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Bar'
    end
  end
end
