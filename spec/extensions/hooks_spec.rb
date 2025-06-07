# frozen_string_literal: true

describe Blueprinter::Hooks do
  let(:blueprint) { Class.new(Blueprinter::V2::Base) }
  let(:field) { Blueprinter::V2::Fields::Field.new(name: :foo, from: :foo) }
  let(:object) { { foo: 'Foo' } }
  let(:render_ctx) { Blueprinter::V2::Context::Render }
  let(:object_ctx) { Blueprinter::V2::Context::Object }
  let(:field_ctx) { Blueprinter::V2::Context::Field }
  let(:result_ctx) { Blueprinter::V2::Context::Result }
  let(:instances) { Blueprinter::V2::InstanceCache.new }
  let(:ext1) do
    Class.new(Blueprinter::Extension) do
      attr_reader :log

      def initialize = @log = []

      def blueprint_setup(_context) = log << 'blueprint_setup'

      def object_output(context)
        context.result[:n] += 1 if context.result[:n]
        context.result
      end

      def exclude_field?(context)
        context.value.nil?
      end
    end
  end
  let(:ext2) do
    Class.new(Blueprinter::Extension) do
      attr_reader :log

      def initialize = @log = []

      def blueprint_setup(_context) = log << 'blueprint_setup'

      def exclude_field?(context)
        context.value == "" || context.value == []
      end
    end
  end

  context '#registered?' do
    it 'knows whether it contains certain hooks' do
      hooks = described_class.new [ext1.new, ext2.new]
      expect(hooks.registered? :object_output).to be true
      expect(hooks.registered? :exclude_field?).to be true
      expect(hooks.registered? :exclude_collection_field?).to be false
    end
  end

  context '#run' do
    it 'runs each hook' do
      exti1 = ext1.new
      exti2 = ext2.new
      hooks = described_class.new [exti1, exti2, Class.new(Blueprinter::Extension)]
      ctx = render_ctx.new(instances.blueprint(blueprint), {})
      hooks.run(:blueprint_setup, ctx)
      expect(exti1.log + exti2.log).to eq ['blueprint_setup', 'blueprint_setup']
    end
  end

  context '#any?' do
    it 'returns true if any hook returns true' do
      hooks = described_class.new [ext1.new, ext2.new]
      ctx = field_ctx.new(instances.blueprint(blueprint), {}, object, field, nil)
      expect(hooks.any?(:exclude_field?, ctx)).to be true
    end

    it 'returns false if no hooks return true' do
      hooks = described_class.new [ext1.new, ext2.new]
      ctx = field_ctx.new(instances.blueprint(blueprint), {}, object, field, 'Foo')
      expect(hooks.any?(:exclude_field?, ctx)).to be false
    end

    it 'returns false if there are no extensions' do
      hooks = described_class.new []
      ctx = field_ctx.new(instances.blueprint(blueprint), {}, object, field, nil)
      expect(hooks.any?(:exclude_field?, ctx)).to be false
    end
  end

  context '#first' do
    it 'returns the value from the first hook' do
      hooks = described_class.new [ext1.new, ext2.new]
      ctx = field_ctx.new(instances.blueprint(blueprint), {}, object, field, '')
      result = hooks.first(:exclude_field?, ctx)
      expect(result).to be false
    end

    it 'returns nil if there are no hooks' do
      hooks = described_class.new []
      ctx = field_ctx.new(instances.blueprint(blueprint), {}, object, field, '')
      result = hooks.first(:exclude_field?, ctx)
      expect(result).to be nil
    end
  end

  context '#last' do
    it 'returns the value from the last hook' do
      hooks = described_class.new [ext1.new, ext2.new]
      ctx = field_ctx.new(instances.blueprint(blueprint), {}, object, field, '')
      result = hooks.last(:exclude_field?, ctx)
      expect(result).to be true
    end

    it 'returns nil if there are no hooks' do
      hooks = described_class.new []
      ctx = field_ctx.new(instances.blueprint(blueprint), {}, object, field, '')
      result = hooks.last(:exclude_field?, ctx)
      expect(result).to be nil
    end
  end

  context '#reduce_hook' do
    it 'returns the final value' do
      hooks = described_class.new [ext1.new, ext2.new, ext1.new, ext1.new]
      ctx = result_ctx.new(instances.blueprint(blueprint), {}, object, { name: 'Foo', n: 0 })
      result = hooks.reduce_hook(:object_output, ctx.result) { |val| ctx.result = val; ctx }
      expect(result).to eq({ name: 'Foo', n: 3 })
    end

    it 'expands a returned array into args' do
      hooks = described_class.new [ext1.new, ext2.new, ext1.new, ext1.new]
      ctx = result_ctx.new(instances.blueprint(blueprint), {}, object, { name: 'Foo', n: 0 })
      result = hooks.reduce_hook(:object_output, ctx.result) { |val| ctx.result = val; [ctx] }
      expect(result).to eq({ name: 'Foo', n: 3 })
    end

    it 'returns the initial value if there are no hooks' do
      hooks = described_class.new []
      ctx = result_ctx.new(instances.blueprint(blueprint), {}, object, { name: 'Foo' })
      result = hooks.reduce_hook(:object_output, ctx.result) { |val| ctx.result = val; ctx }
      expect(result).to eq({ name: 'Foo' })
    end
  end

  context '#reduce_into' do
    it 'returns the final value' do
      hooks = described_class.new [ext1.new, ext2.new, ext1.new, ext1.new]
      ctx = result_ctx.new(instances.blueprint(blueprint), {}, object, { name: 'Foo', n: 0 })
      result = hooks.reduce_into(:object_output, ctx, :result)
      expect(result).to eq({ name: 'Foo', n: 3 })
    end

    it 'expands a returned array into args' do
      hooks = described_class.new [ext1.new, ext2.new, ext1.new, ext1.new]
      ctx = result_ctx.new(instances.blueprint(blueprint), {}, object, { name: 'Foo', n: 0 })
      result = hooks.reduce_into(:object_output, ctx, :result)
      expect(result).to eq({ name: 'Foo', n: 3 })
    end

    it 'returns the initial value if there are no hooks' do
      hooks = described_class.new []
      ctx = result_ctx.new(instances.blueprint(blueprint), {}, object, { name: 'Foo' })
      result = hooks.reduce_into(:object_output, ctx, :result)
      expect(result).to eq({ name: 'Foo' })
    end
  end

  context '#around' do
    let(:ext_a) do
      Class.new(Blueprinter::Extension) do
        def initialize(log)
          @log = log
        end

        def around_serialize_object(ctx)
          @log << "A: #{ctx.test_value}"
          yield
          @log << "A END"
        end
      end
    end

    let(:ext_b) do
      Class.new(ext_a) do
        def around_serialize_object(ctx)
          @log << "B: #{ctx.test_value}"
          yield
          @log << "B END"
        end
      end
    end

    let(:ext_c) do
      Class.new(ext_a) do
        def around_serialize_object(ctx)
          @log << "C: #{ctx.test_value}"
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

          def around_serialize_object(_ctx)
            @log << 'around_serialize_object: A'
            yield
            @log << 'around_serialize_object: B'
          end

          def around_hook(ctx)
            @log << "around_hook(#{ctx.extension.class.name}##{ctx.hook}): A"
            yield
            @log << "around_hook(#{ctx.extension.class.name}##{ctx.hook}): B"
          end
        end
      end

      it 'is called around other extension hooks' do
        log = []
        hooks = described_class.new [ext1.new(log), ext2.new(log)]

        ctx = field_ctx.new(instances.blueprint(blueprint), {}, object, field, 42)
        hooks.reduce_into(:field_value, ctx, :value)

        ctx = object_ctx.new(instances.blueprint(blueprint), {}, object)
        hooks.around(:around_serialize_object, ctx) { log << 'INNER' }

        expect(log).to eq [
          "around_hook(#{ext1.name}#field_value): A",
          'field_value',
          "around_hook(#{ext1.name}#field_value): B",
          "around_hook(#{ext2.name}#around_serialize_object): A",
          'around_serialize_object: A',
          'INNER',
          'around_serialize_object: B',
          "around_hook(#{ext2.name}#around_serialize_object): B"
        ]
      end

      it 'is skipped for hidden extensions' do
        ext2.class_eval { def hidden? = true }
        log = []
        ctx = field_ctx.new(instances.blueprint(blueprint), {}, object, field, 42)
        hooks = described_class.new [ext1.new(log), ext2.new(log)]

        hooks.reduce_into(:field_value, ctx, :value)
        hooks.around(:around_serialize_object, ctx) { log << 'INNER' }
        expect(log).to eq [
          "around_hook(#{ext1.name}#field_value): A",
          'field_value',
          "around_hook(#{ext1.name}#field_value): B",
          'around_serialize_object: A',
          'INNER',
          'around_serialize_object: B',
        ]
      end
    end

    it 'nests calls' do
      log = []
      extensions = [ext_a.new(log), ext_b.new(log), ext_c.new(log)]
      ctx = object_ctx.new(instances.blueprint(blueprint), {}, object)
      def ctx.test_value = 42
      hooks = described_class.new extensions
      hooks.around(:around_serialize_object, ctx) { log << 'INNER' }
      expect(log).to eq ['A: 42', 'B: 42', 'C: 42', 'INNER', 'C END', 'B END', 'A END',]
    end

    it 'returns the inner value' do
      ctx = object_ctx.new(instances.blueprint(blueprint), {}, object)
      def ctx.test_value = 42
      hooks = described_class.new [ext_a.new([]), ext_b.new([]), ext_c.new([])]
      result = hooks.around(:around_serialize_object, ctx) { 42 }
      expect(result).to eq 42
    end

    it 'returns the inner with no hooks' do
      ctx = object_ctx.new(instances.blueprint(blueprint), {}, object)
      hooks = described_class.new []
      result = hooks.around(:around_serialize_object, ctx) { 42 }
      expect(result).to eq 42
    end

    it "raises if a hook doesn't yield" do
      ext = Class.new(Blueprinter::Extension) do
        def around_serialize_object(_ctx); end
      end
      ctx = object_ctx.new(instances.blueprint(blueprint), {}, object)
      hooks = described_class.new [ext.new]
      expect { hooks.around(:around_serialize_object, ctx) { 42 } }.to raise_error Blueprinter::BlueprinterError
    end

    it 'raises if a hook yields more than once' do
      ext = Class.new(Blueprinter::Extension) do
        def around_serialize_object(_ctx)
          yield
          yield
        end
      end
      ctx = object_ctx.new(instances.blueprint(blueprint), {}, object)
      hooks = described_class.new [ext.new]
      expect { hooks.around(:around_serialize_object, ctx) { 42 } }.to raise_error Blueprinter::BlueprinterError
    end
  end
end
