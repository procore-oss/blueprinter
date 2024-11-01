# frozen_string_literal: true

describe Blueprinter::Hooks do
  let(:blueprint) { Class.new(Blueprinter::V2::Base) }
  let(:field) { Blueprinter::V2::Field.new(name: :foo, from: :foo) }
  let(:object) { { foo: 'Foo' } }
  let(:context) { Blueprinter::V2::Context }
  let(:ext1) do
    Class.new(Blueprinter::Extension) do
      def output_object(context)
        context.value[:n] += 1 if context.value[:n]
        context.value
      end

      def exclude_field?(context)
        context.value.nil?
      end
    end
  end
  let(:ext2) do
    Class.new(Blueprinter::Extension) do
      def exclude_field?(context)
        context.value == "" || context.value == []
      end
    end
  end

  context 'any?' do
    it 'should return true if any hook returns true' do
      hooks = described_class.new [ext1.new, ext2.new]
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(hooks.any?(:exclude_field?, ctx)).to be true
    end

    it 'should return false if no hooks return true' do
      hooks = described_class.new [ext1.new, ext2.new]
      ctx = context.new(blueprint.new, field, { name: 'Foo' }, object, {})
      expect(hooks.any?(:exclude_field?, ctx)).to be false
    end

    it 'should return false if there are no extensions' do
      hooks = described_class.new []
      ctx = context.new(blueprint.new, field, nil, object, {})
      expect(hooks.any?(:exclude_field?, ctx)).to be false
    end
  end

  context 'last' do
    it 'should return the value from the last hook' do
      hooks = described_class.new [ext1.new, ext2.new]
      ctx = context.new(blueprint.new, field, '', object, {})
      result = hooks.last(:exclude_field?, ctx)
      expect(result).to be true
    end

    it 'should reutrn nil if there are no hooks' do
      hooks = described_class.new []
      ctx = context.new(blueprint.new, field, { name: 'Foo', n: 0 }, object, {})
      result = hooks.last(:exclude_field?, ctx)
      expect(result).to be nil
    end
  end

  context 'reduce' do
    it 'should return the final value' do
      hooks = described_class.new [ext1.new, ext2.new, ext1.new, ext1.new]
      ctx = context.new(blueprint.new, field, { name: 'Foo', n: 0 }, object, {})
      result = hooks.reduce(:output_object, ctx.value) { |val| ctx.value = val; ctx }
      expect(result).to eq({ name: 'Foo', n: 3 })
    end

    it 'should expand a returned array into args' do
      hooks = described_class.new [ext1.new, ext2.new, ext1.new, ext1.new]
      ctx = context.new(blueprint.new, field, { name: 'Foo', n: 0 }, object, {})
      result = hooks.reduce(:output_object, ctx.value) { |val| ctx.value = val; [ctx] }
      expect(result).to eq({ name: 'Foo', n: 3 })
    end

    it 'should return the initial value if there are no hooks' do
      hooks = described_class.new []
      ctx = context.new(blueprint.new, field, { name: 'Foo' }, object, {})
      result = hooks.reduce(:output_object, ctx.value) { |val| ctx.value = val; ctx }
      expect(result).to eq({ name: 'Foo' })
    end
  end

  context 'reduce_into' do
    it 'should return the final value' do
      hooks = described_class.new [ext1.new, ext2.new, ext1.new, ext1.new]
      ctx = context.new(blueprint.new, field, { name: 'Foo', n: 0 }, object, {})
      result = hooks.reduce_into(:output_object, ctx, :value)
      expect(result).to eq({ name: 'Foo', n: 3 })
    end

    it 'should expand a returned array into args' do
      hooks = described_class.new [ext1.new, ext2.new, ext1.new, ext1.new]
      ctx = context.new(blueprint.new, field, { name: 'Foo', n: 0 }, object, {})
      result = hooks.reduce_into(:output_object, ctx, :value)
      expect(result).to eq({ name: 'Foo', n: 3 })
    end

    it 'should return the initial value if there are no hooks' do
      hooks = described_class.new []
      ctx = context.new(blueprint.new, field, { name: 'Foo' }, object, {})
      result = hooks.reduce_into(:output_object, ctx, :value)
      expect(result).to eq({ name: 'Foo' })
    end
  end
end
