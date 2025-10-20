# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Core::Conditionals do
  include ExtensionHelpers
  let(:object) { { foo: 'Foo' } }
  let(:skip_field) { Blueprinter::V2::Serializer::SKIP }

  context 'fields' do
    let(:field) { blueprint.reflections[:default].fields[:foo] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'
    end

    it 'checks options field_unless (Proc)' do
      ctx = prepare(blueprint, { field_unless: ->(val, ctx) { foo? val, ctx } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { 'Bar' }
      expect(value).to eq 'Bar'
    end

    it 'checks field options unless (Proc)' do
      blueprint.field :foo, unless: ->(val, ctx) { foo? val, ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { 'Bar' }
      expect(value).to eq 'Bar'
    end

    it 'checks blueprint options field_unless (Proc)' do
      blueprint.options[:field_unless] = ->(val, ctx) { foo? val, ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { 'Bar' }
      expect(value).to eq 'Bar'
    end

    it 'checks options field_unless (Symbol)' do
      ctx = prepare(blueprint, { field_unless: :foo? }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { 'Bar' }
      expect(value).to eq 'Bar'
    end

    it 'checks field options unless (Symbol)' do
      blueprint.field :foo, unless: :foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { 'Bar' }
      expect(value).to eq 'Bar'
    end

    it 'checks blueprint options field_unless (Symbol)' do
      blueprint.options[:field_unless] = :foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { 'Bar' }
      expect(value).to eq 'Bar'
    end
  end

  context 'objects' do
    let(:field) { blueprint.reflections[:default].objects[:foo_obj] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'
    end

    it 'checks options object_unless (Proc)' do
      ctx = prepare(blueprint, { object_unless: ->(val, ctx) { name_foo? val, ctx } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { { name: 'Foo' } }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { { name: 'Bar' } }
      expect(value).to eq({ name: 'Bar' })
    end

    it 'checks field options unless (Proc)' do
      blueprint.object :foo_obj, sub_blueprint, unless: ->(val, ctx) { name_foo? val, ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { { name: 'Foo' } }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { { name: 'Bar' } }
      expect(value).to eq({ name: 'Bar' })
    end

    it 'checks blueprint options object_unless (Proc)' do
      blueprint.options[:object_unless] = ->(val, ctx) { name_foo? val, ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { { name: 'Foo' } }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { { name: 'Bar' } }
      expect(value).to eq({ name: 'Bar' })
    end

    it 'checks options object_unless (Symbol)' do
      ctx = prepare(blueprint, { object_unless: :name_foo? }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { { name: 'Foo' } }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { { name: 'Bar' } }
      expect(value).to eq({ name: 'Bar' })
    end

    it 'checks field options unless (Symbol)' do
      blueprint.object :foo_obj, sub_blueprint, unless: :name_foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { { name: 'Foo' } }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { { name: 'Bar' } }
      expect(value).to eq({ name: 'Bar' })
    end

    it 'checks blueprint options object_unless (Symbol)' do
      blueprint.options[:object_unless] = :name_foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { { name: 'Foo' } }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { { name: 'Bar' } }
      expect(value).to eq({ name: 'Bar' })
    end
  end

  context 'collections' do
    let(:field) { blueprint.reflections[:default].collections[:foos] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { [{ name: 'Foo' }] }
      expect(value).to eq([{ name: 'Foo' }])
    end

    it 'checks options collection_unless (Proc)' do
      ctx = prepare(blueprint, { collection_unless: ->(val, ctx) { names_foo? val, ctx } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { [{ name: 'Foo' }] }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { [{ name: 'Bar' }] }
      expect(value).to eq([{ name: 'Bar' }])
    end

    it 'checks field options unless (Proc)' do
      blueprint.collection :foos, sub_blueprint, unless: ->(val, ctx) { names_foo? val, ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { [{ name: 'Foo' }] }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { [{ name: 'Bar' }] }
      expect(value).to eq([{ name: 'Bar' }])
    end

    it 'checks blueprint options collection_unless (Proc)' do
      blueprint.options[:collection_unless] = ->(val, ctx) { names_foo? val, ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { [{ name: 'Foo' }] }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { [{ name: 'Bar' }] }
      expect(value).to eq([{ name: 'Bar' }])
    end

    it 'checks options collection_unless (Symbol)' do
      ctx = prepare(blueprint, { collection_unless: :names_foo? }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { [{ name: 'Foo' }] }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { [{ name: 'Bar' }] }
      expect(value).to eq([{ name: 'Bar' }])
    end

    it 'checks field options unless (Symbol)' do
      blueprint.collection :foos, sub_blueprint, unless: :names_foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { [{ name: 'Foo' }] }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { [{ name: 'Bar' }] }
      expect(value).to eq([{ name: 'Bar' }])
    end

    it 'checks blueprint options collection_unless (Symbol)' do
      blueprint.options[:collection_unless] = :names_foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_field_value(ctx) { [{ name: 'Foo' }] }
      expect(value).to eq skip_field

      value = subject.around_field_value(ctx) { [{ name: 'Bar' }] }
      expect(value).to eq([{ name: 'Bar' }])
    end
  end
end
