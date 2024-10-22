# frozen_string_literal: true

describe Blueprinter::V2::Hooks do
  let(:blueprint) { Class.new(Blueprinter::V2::Base) }
  let(:field) { Blueprinter::V2::Field.new(name: :foo, from: :foo) }
  let(:object) { { foo: 'Foo' } }
  let(:context) { Blueprinter::V2::Serializer::Context }

  it 'should extract hooks' do
    ext1 = Class.new(Blueprinter::V2::Extension) do
      def input(_blueprint, obj, _opts)
        obj[:bar] = 'Bar' if obj[:foo]
        obj
      end

      def exclude_field?(context)
        context.value.nil? || !!context.options[:always_include]
      end
    end

    ext2 = Class.new(Blueprinter::V2::Extension) do
      def exclude_field?(context)
        context.value == "" || context.value == []
      end
    end

    hooks = described_class.new [ext1.new, ext2.new]
    expect(hooks.reduce(:input, { foo: 'Foo' }) { |acc| [blueprint.new, acc, {}] }).to eq({ foo: 'Foo', bar: 'Bar' })
    expect(hooks.reduce(:input, { zorp: 'Zorp' }) { |acc| [blueprint.new, acc, {}] }).to eq({ zorp: 'Zorp' })
    expect(hooks.any?(:exclude_field?, context.new(blueprint.new, field, :foo, object, {}))).to be false
    expect(hooks.any?(:exclude_field?, context.new(blueprint.new, field, nil, object, {}))).to be true
    expect(hooks.any?(:exclude_field?, context.new(blueprint.new, field, "", object, {}))).to be true
  end

  it 'should work with no extensions' do
    hooks = described_class.new []
    expect(hooks.reduce(:input, { foo: 'Foo' }) { |acc| [blueprint.new, acc, {}] }).to eq({ foo: 'Foo' })
    expect(hooks.any?(:exclude_field?, context.new(blueprint.new, field, :foo, object, {}))).to be false
  end
end
