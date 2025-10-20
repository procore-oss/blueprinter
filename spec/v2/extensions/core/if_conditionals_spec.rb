# frozen_string_literal: true

describe Blueprinter::V2::Extensions::Core::Conditionals do
  include ExtensionHelpers
  let(:object) { { foo: 'Foo' } }
  let(:skip_field) { Blueprinter::V2::Serializer::SKIP }

  context 'fields' do
    let(:field) { blueprint.reflections[:default].fields[:foo] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'
    end

    it 'checks options field_if (Proc)' do
      ctx = prepare(blueprint, { field_if: ->(val, ctx) { foo? val, ctx } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'

      value = subject.around_object_value(ctx) { 'Bar' }
      expect(value).to eq skip_field
    end

    it 'checks field options if (Proc)' do
      blueprint.field :foo, if: ->(val, ctx) { foo? val, ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'

      value = subject.around_object_value(ctx) { 'Bar' }
      expect(value).to eq skip_field
    end

    it 'checks blueprint options field_if (Proc)' do
      blueprint.options[:field_if] = ->(val, ctx) { foo? val, ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'

      value = subject.around_object_value(ctx) { 'Bar' }
      expect(value).to eq skip_field
    end

    it 'checks options field_if (Symbol)' do
      ctx = prepare(blueprint, { field_if: :foo? }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'

      value = subject.around_object_value(ctx) { 'Bar' }
      expect(value).to eq skip_field
    end

    it 'checks field options if (Symbol)' do
      blueprint.field :foo, if: :foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'

      value = subject.around_object_value(ctx) { 'Bar' }
      expect(value).to eq skip_field
    end

    it 'checks blueprint options field_if (Symbol)' do
      blueprint.options[:field_if] = :foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { 'Foo' }
      expect(value).to eq 'Foo'

      value = subject.around_object_value(ctx) { 'Bar' }
      expect(value).to eq skip_field
    end
  end

  context 'objects' do
    let(:field) { blueprint.reflections[:default].objects[:foo_obj] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { { name: 'Foo' } }
      expect(value).to eq({ name: 'Foo' })
    end

    it 'checks options object_if (Proc)' do
      ctx = prepare(blueprint, { object_if: ->(val, ctx) { name_foo? val, ctx } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { { name: 'Foo' } }
      expect(value).to eq({ name: 'Foo' })

      value = subject.around_object_value(ctx) { { name: 'Bar' } }
      expect(value).to eq skip_field
    end

    it 'checks field options if (Proc)' do
      blueprint.object :foo_obj, sub_blueprint, if: ->(val, ctx) { name_foo? val, ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { { name: 'Foo' } }
      expect(value).to eq({ name: 'Foo' })

      value = subject.around_object_value(ctx) { { name: 'Bar' } }
      expect(value).to eq skip_field
    end

    it 'checks blueprint options object_if (Proc)' do
      blueprint.options[:object_if] = ->(val, ctx) { name_foo? val, ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { { name: 'Foo' } }
      expect(value).to eq({ name: 'Foo' })

      value = subject.around_object_value(ctx) { { name: 'Bar' } }
      expect(value).to eq skip_field
    end

    it 'checks options object_if (Symbol)' do
      ctx = prepare(blueprint, { object_if: :name_foo? }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { { name: 'Foo' } }
      expect(value).to eq({ name: 'Foo' })

      value = subject.around_object_value(ctx) { { name: 'Bar' } }
      expect(value).to eq skip_field
    end

    it 'checks field options if (Symbol)' do
      blueprint.object :foo_obj, sub_blueprint, if: :name_foo?
      ctx = prepare(blueprint, { object_if: :name_foo? }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { { name: 'Foo' } }
      expect(value).to eq({ name: 'Foo' })

      value = subject.around_object_value(ctx) { { name: 'Bar' } }
      expect(value).to eq skip_field
    end

    it 'checks blueprint options object_if (Symbol)' do
      blueprint.options[:object_if] = :name_foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { { name: 'Foo' } }
      expect(value).to eq({ name: 'Foo' })

      value = subject.around_object_value(ctx) { { name: 'Bar' } }
      expect(value).to eq skip_field
    end
  end

  context 'collections' do
    let(:field) { blueprint.reflections[:default].collections[:foos] }

    it 'are allowed by default' do
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { [{ name: 'Foo' }] }
      expect(value).to eq [{ name: 'Foo' }]
    end

    it 'checks options collection_if (Proc)' do
      ctx = prepare(blueprint, { collection_if: ->(val, ctx) { names_foo? val, ctx } }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { [{ name: 'Foo' }] }
      expect(value).to eq [{ name: 'Foo' }]

      value = subject.around_object_value(ctx) { [{ name: 'Bar' }] }
      expect(value).to eq skip_field
    end

    it 'checks field options if (Proc)' do
      blueprint.collection :foos, sub_blueprint, if: ->(val, ctx) { names_foo? val, ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { [{ name: 'Foo' }] }
      expect(value).to eq [{ name: 'Foo' }]

      value = subject.around_object_value(ctx) { [{ name: 'Bar' }] }
      expect(value).to eq skip_field
    end

    it 'checks blueprint options collection_if (Proc)' do
      blueprint.options[:collection_if] = ->(val, ctx) { names_foo? val, ctx }
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { [{ name: 'Foo' }] }
      expect(value).to eq [{ name: 'Foo' }]

      value = subject.around_object_value(ctx) { [{ name: 'Bar' }] }
      expect(value).to eq skip_field
    end

    it 'checks options collection_if (Symbol)' do
      ctx = prepare(blueprint, { collection_if: :names_foo? }, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { [{ name: 'Foo' }] }
      expect(value).to eq [{ name: 'Foo' }]

      value = subject.around_object_value(ctx) { [{ name: 'Bar' }] }
      expect(value).to eq skip_field
    end

    it 'checks field options if (Symbol)' do
      blueprint.collection :foos, sub_blueprint, if: :names_foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { [{ name: 'Foo' }] }
      expect(value).to eq [{ name: 'Foo' }]

      value = subject.around_object_value(ctx) { [{ name: 'Bar' }] }
      expect(value).to eq skip_field
    end

    it 'checks blueprint options collection_if (Symbol)' do
      blueprint.options[:collection_if] = :names_foo?
      ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Field, object, field)
      value = subject.around_object_value(ctx) { [{ name: 'Foo' }] }
      expect(value).to eq [{ name: 'Foo' }]

      value = subject.around_object_value(ctx) { [{ name: 'Bar' }] }
      expect(value).to eq skip_field
    end
  end
end
