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

  context '#has?' do
    it 'should know whether it contains certain hooks' do
      hooks = described_class.new [ext1.new, ext2.new]
      expect(hooks.has? :output_object).to be true
      expect(hooks.has? :exclude_field?).to be true
      expect(hooks.has? :exclude_collection?).to be false
    end
  end

  context '#any?' do
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

  context '#first' do
    it 'should return the value from the first hook' do
      hooks = described_class.new [ext1.new, ext2.new]
      ctx = context.new(blueprint.new, field, '', object, {})
      result = hooks.first(:exclude_field?, ctx)
      expect(result).to be false
    end

    it 'should reutrn nil if there are no hooks' do
      hooks = described_class.new []
      ctx = context.new(blueprint.new, field, { name: 'Foo', n: 0 }, object, {})
      result = hooks.first(:exclude_field?, ctx)
      expect(result).to be nil
    end
  end

  context '#last' do
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

  context '#reduce' do
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

  context '#reduce_into' do
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

  context '#around' do
    let(:ext_a) do
      Class.new(Blueprinter::Extension) do
        def initialize(log)
          @log = log
        end

        def around_object(ctx)
          @log << "A: #{ctx.store[:value]}"
          yield
          @log << "A END"
        end
      end
    end

    let(:ext_b) do
      Class.new(ext_a) do
        def around_object(ctx)
          @log << "B: #{ctx.store[:value]}"
          yield
          @log << "B END"
        end
      end
    end

    let(:ext_c) do
      Class.new(ext_a) do
        def around_object(ctx)
          @log << "C: #{ctx.store[:value]}"
          yield
          @log << "C END"
        end
      end
    end

    context '#around_hook' do
      let(:ext1) do
        Class.new(Blueprinter::Extension) do
          def self.name = 'TestExt1'

          def initialize(log) = @log = log

          def field_value(ctx)
            @log << 'field_value'
            'Value'
          end
        end
      end

      let(:ext2) do
        Class.new(Blueprinter::Extension) do
          def initialize(log) = @log = log

          def around_object(_ctx)
            @log << 'around_object: A'
            yield
            @log << 'around_object: B'
          end

          def around_hook(ext, hook)
            @log << "around_hook(#{ext.class.name}##{hook}): A"
            yield
            @log << "around_hook(#{ext.class.name}##{hook}): B"
          end
        end
      end

      it 'should be called around other extension hooks' do
        log = []
        ctx = Blueprinter::V2::Context.new(nil, nil, nil, nil, nil, nil, { value: 42 })
        hooks = described_class.new [ext1.new(log), ext2.new(log)]

        hooks.reduce_into(:field_value, ctx, :value)
        hooks.around(:around_object, ctx) { log << 'INNER' }
        expect(log).to eq [
          "around_hook(#{ext1.name}#field_value): A",
          'field_value',
          "around_hook(#{ext1.name}#field_value): B",
          "around_hook(#{ext2.name}#around_object): A",
          'around_object: A',
          'INNER',
          'around_object: B',
          "around_hook(#{ext2.name}#around_object): B"
        ]
      end

      it 'should be skipped for hidden extensions' do
        ext2.class_eval { def hidden? = true }
        log = []
        ctx = Blueprinter::V2::Context.new(nil, nil, nil, nil, nil, nil, { value: 42 })
        hooks = described_class.new [ext1.new(log), ext2.new(log)]

        hooks.reduce_into(:field_value, ctx, :value)
        hooks.around(:around_object, ctx) { log << 'INNER' }
        expect(log).to eq [
          "around_hook(#{ext1.name}#field_value): A",
          'field_value',
          "around_hook(#{ext1.name}#field_value): B",
          'around_object: A',
          'INNER',
          'around_object: B',
        ]
      end
    end

    it 'should nest calls' do
      log = []
      ctx = Blueprinter::V2::Context.new(nil, nil, nil, nil, nil, nil, { value: 42 })
      hooks = described_class.new [ext_a.new(log), ext_b.new(log), ext_c.new(log)]
      hooks.around(:around_object, ctx) { log << 'INNER' }
      expect(log).to eq ['A: 42', 'B: 42', 'C: 42', 'INNER', 'C END', 'B END', 'A END',]
    end

    it 'should return the inner value' do
      ctx = Blueprinter::V2::Context.new(nil, nil, nil, nil, nil, nil, {})
      hooks = described_class.new [ext_a.new([]), ext_b.new([]), ext_c.new([])]
      result = hooks.around(:around_object, ctx) { 42 }
      expect(result).to eq 42
    end

    it 'should return the inner with no hooks' do
      ctx = Blueprinter::V2::Context.new(nil, nil, nil, nil, nil, nil, {})
      hooks = described_class.new []
      result = hooks.around(:around_object, ctx) { 42 }
      expect(result).to eq 42
    end

    it "should raise if a hook doesn't yield" do
      ext = Class.new(Blueprinter::Extension) do
        def around_object(_ctx); end
      end
      ctx = Blueprinter::V2::Context.new(nil, nil, nil, nil, nil, nil, {})
      hooks = described_class.new [ext.new]
      expect { hooks.around(:around_object, ctx) { 42 } }.to raise_error Blueprinter::BlueprinterError
    end

    it 'should raise if a hook yields more than once' do
      ext = Class.new(Blueprinter::Extension) do
        def around_object(_ctx)
          yield
          yield
        end
      end
      ctx = Blueprinter::V2::Context.new(nil, nil, nil, nil, nil, nil, {})
      hooks = described_class.new [ext.new]
      expect { hooks.around(:around_object, ctx) { 42 } }.to raise_error Blueprinter::BlueprinterError
    end
  end
end
