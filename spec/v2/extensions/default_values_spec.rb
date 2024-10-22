# frozen_string_literal: true

describe Blueprinter::V2::Extensions::DefaultValues do
  subject { described_class.new }
  let(:context) { Blueprinter::V2::Serializer::Context }
  let(:blueprint) { Class.new(Blueprinter::V2::Base) }
  let(:object) { { name: 'Foo' } }

  context 'fields' do
    let(:field) { Blueprinter::V2::Field.new(name: :name, from: :name, options: {}) }

    it 'should pass values through by default' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.field_value ctx).to eq 'Foo'
    end

    it 'should pass values through by with defaults given' do
      blueprint.options[:field_default] = 'Bar'
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default: 'Bar' })
      expect(subject.field_value ctx).to eq 'Foo'
    end

    it 'should pass values through with false defaults_ifs given' do
      blueprint.options[:field_default] = 'Bar'
      blueprint.options[:field_default_if] = ->(_) { false }
      field.options[:default] = 'Bar'
      field.options[:default_if] = ->(_) { false }
      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default: 'Bar', field_default_if: ->(_) { false } })
      expect(subject.field_value ctx).to eq 'Foo'
    end

    it 'should pass nil through by default' do
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.field_value ctx).to be_nil
    end

    it 'should use options field_default' do
      ctx = context.new(blueprint.new, field, nil, object, { field_default: 'Bar' })
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should use options field_default (Proc)' do
      ctx = context.new(blueprint.new, field, nil, object, { field_default: ->(ctx) { "Bar (was #{ctx.value.inspect})"} })
      expect(subject.field_value ctx).to eq 'Bar (was nil)'
    end

    it 'should use field options default' do
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should use field options default (Proc)' do
      field.options[:default] = ->(ctx) { "Bar (was #{ctx.value.inspect})"}
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'Bar (was nil)'
    end

    it 'should use blueprint options field_default' do
      blueprint.options[:field_default] = 'Bar'
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should use blueprint options field_default (Proc)' do
      blueprint.options[:field_default] = ->(ctx) { "Bar (was #{ctx.value.inspect})"}
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.field_value ctx).to eq 'Bar (was nil)'
    end

    it 'should check with options field_default_if (default = options field_default)' do
      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default: 'Bar', field_default_if: ->(ctx) { ctx.value == 'Foo' } })
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should check with options field_default_if (default = field options default)' do
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default_if: ->(ctx) { ctx.value == 'Foo' } })
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should check with options field_default_if (default = blueprint options field_default)' do
      blueprint.options[:field_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default_if: ->(ctx) { ctx.value == 'Foo' } })
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = options field_default)' do
      field.options[:default_if] = ->(ctx) { ctx.value == 'Foo' }
      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default: 'Bar' })
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = field options default)' do
      field.options[:default_if] = ->(ctx) { ctx.value == 'Foo' }
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = blueprint options field_default)' do
      field.options[:default_if] = ->(ctx) { ctx.value == 'Foo' }
      blueprint.options[:field_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options field_default_if (default = options field_default)' do
      blueprint.options[:field_default_if] = ->(ctx) { ctx.value == 'Foo' }
      ctx = context.new(blueprint.new, field, 'Foo', object, { field_default: 'Bar' })
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options field_default_if (default = field options default)' do
      blueprint.options[:field_default_if] = ->(ctx) { ctx.value == 'Foo' }
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.field_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options field_default_if (default = blueprint options field_default)' do
      blueprint.options[:field_default_if] = ->(ctx) { ctx.value == 'Foo' }
      blueprint.options[:field_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.field_value ctx).to eq 'Bar'
    end
  end

  context 'objects' do
    let(:field) { Blueprinter::V2::Association.new(name: :name, from: :name, collection: false, options: {}) }

    it 'should pass values through by default' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.object_value ctx).to eq 'Foo'
    end

    it 'should pass values through by with defaults given' do
      blueprint.options[:object_default] = 'Bar'
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default: 'Bar' })
      expect(subject.object_value ctx).to eq 'Foo'
    end

    it 'should pass values through with false defaults_ifs given' do
      blueprint.options[:object_default] = 'Bar'
      blueprint.options[:object_default_if] = ->(_) { false }
      field.options[:default] = 'Bar'
      field.options[:default_if] = ->(_) { false }
      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default: 'Bar', object_default_if: ->(_) { false } })
      expect(subject.object_value ctx).to eq 'Foo'
    end

    it 'should pass nil through by default' do
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.object_value ctx).to be_nil
    end

    it 'should use options object_default' do
      ctx = context.new(blueprint.new, field, nil, object, { object_default: 'Bar' })
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should use options object_default (Proc)' do
      ctx = context.new(blueprint.new, field, nil, object, { object_default: ->(ctx) { "Bar (was #{ctx.value.inspect})"} })
      expect(subject.object_value ctx).to eq 'Bar (was nil)'
    end

    it 'should use field options default' do
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should use field options default (Proc)' do
      field.options[:default] = ->(ctx) { "Bar (was #{ctx.value.inspect})"}
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Bar (was nil)'
    end

    it 'should use blueprint options object_default' do
      blueprint.options[:object_default] = 'Bar'
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should use blueprint options object_default (Proc)' do
      blueprint.options[:object_default] = ->(ctx) { "Bar (was #{ctx.value.inspect})"}
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.object_value ctx).to eq 'Bar (was nil)'
    end

    it 'should check with options object_default_if (default = options object_default)' do
      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default: 'Bar', object_default_if: ->(ctx) { ctx.value == 'Foo' } })
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should check with options object_default_if (default = field options default)' do
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default_if: ->(ctx) { ctx.value == 'Foo' } })
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should check with options object_default_if (default = blueprint options object_default)' do
      blueprint.options[:object_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default_if: ->(ctx) { ctx.value == 'Foo' } })
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = options object_default)' do
      field.options[:default_if] = ->(ctx) { ctx.value == 'Foo' }
      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default: 'Bar' })
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = field options default)' do
      field.options[:default_if] = ->(ctx) { ctx.value == 'Foo' }
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = blueprint options object_default)' do
      field.options[:default_if] = ->(ctx) { ctx.value == 'Foo' }
      blueprint.options[:object_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options object_default_if (default = options object_default)' do
      blueprint.options[:object_default_if] = ->(ctx) { ctx.value == 'Foo' }
      ctx = context.new(blueprint.new, field, 'Foo', object, { object_default: 'Bar' })
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options object_default_if (default = field options default)' do
      blueprint.options[:object_default_if] = ->(ctx) { ctx.value == 'Foo' }
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.object_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options object_default_if (default = blueprint options object_default)' do
      blueprint.options[:object_default_if] = ->(ctx) { ctx.value == 'Foo' }
      blueprint.options[:object_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.object_value ctx).to eq 'Bar'
    end
  end

  context 'collections' do
    let(:field) { Blueprinter::V2::Association.new(name: :name, from: :name, collection: true, options: {}) }

    it 'should pass values through by default' do
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.collection_value ctx).to eq 'Foo'
    end

    it 'should pass values through by with defaults given' do
      blueprint.options[:collection_default] = 'Bar'
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default: 'Bar' })
      expect(subject.collection_value ctx).to eq 'Foo'
    end

    it 'should pass values through with false defaults_ifs given' do
      blueprint.options[:collection_default] = 'Bar'
      blueprint.options[:collection_default_if] = ->(_) { false }
      field.options[:default] = 'Bar'
      field.options[:default_if] = ->(_) { false }
      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default: 'Bar', collection_default_if: ->(_) { false } })
      expect(subject.collection_value ctx).to eq 'Foo'
    end

    it 'should pass nil through by default' do
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.collection_value ctx).to be_nil
    end

    it 'should use options collection_default' do
      ctx = context.new(blueprint.new, field, nil, object, { collection_default: 'Bar' })
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should use options collection_default (Proc)' do
      ctx = context.new(blueprint.new, field, nil, object, { collection_default: ->(ctx) { "Bar (was #{ctx.value.inspect})"} })
      expect(subject.collection_value ctx).to eq 'Bar (was nil)'
    end

    it 'should use field options default' do
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should use field options default (Proc)' do
      field.options[:default] = ->(ctx) { "Bar (was #{ctx.value.inspect})"}
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Bar (was nil)'
    end

    it 'should use blueprint options collection_default' do
      blueprint.options[:collection_default] = 'Bar'
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should use blueprint options collection_default (Proc)' do
      blueprint.options[:collection_default] = ->(ctx) { "Bar (was #{ctx.value.inspect})"}
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(subject.collection_value ctx).to eq 'Bar (was nil)'
    end

    it 'should check with options collection_default_if (default = options collection_default)' do
      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default: 'Bar', collection_default_if: ->(ctx) { ctx.value == 'Foo' } })
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should check with options collection_default_if (default = field options default)' do
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default_if: ->(ctx) { ctx.value == 'Foo' } })
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should check with options collection_default_if (default = blueprint options collection_default)' do
      blueprint.options[:collection_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default_if: ->(ctx) { ctx.value == 'Foo' } })
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = options collection_default)' do
      field.options[:default_if] = ->(ctx) { ctx.value == 'Foo' }
      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default: 'Bar' })
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = field options default)' do
      field.options[:default_if] = ->(ctx) { ctx.value == 'Foo' }
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should check with field options default_if (default = blueprint options collection_default)' do
      field.options[:default_if] = ->(ctx) { ctx.value == 'Foo' }
      blueprint.options[:collection_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options collection_default_if (default = options collection_default)' do
      blueprint.options[:collection_default_if] = ->(ctx) { ctx.value == 'Foo' }
      ctx = context.new(blueprint.new, field, 'Foo', object, { collection_default: 'Bar' })
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options collection_default_if (default = field options default)' do
      blueprint.options[:collection_default_if] = ->(ctx) { ctx.value == 'Foo' }
      field.options[:default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.collection_value ctx).to eq 'Bar'
    end

    it 'should check with blueprint options collection_default_if (default = blueprint options collection_default)' do
      blueprint.options[:collection_default_if] = ->(ctx) { ctx.value == 'Foo' }
      blueprint.options[:collection_default] = 'Bar'
      ctx = context.new(blueprint.new, field, 'Foo', object, {})
      expect(subject.collection_value ctx).to eq 'Bar'
    end
  end
end
