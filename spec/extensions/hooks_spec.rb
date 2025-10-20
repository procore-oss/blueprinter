# frozen_string_literal: true

describe Blueprinter::Hooks do
  let(:skip_field) { Blueprinter::V2::Serializer::SKIP }
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      fields :name, :description
    end
  end
  let(:serializer) { Blueprinter::V2::Serializer.new(blueprint, {}, instances, initial_depth: 1) }
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

      def around_blueprint_init(ctx)
        ctx.fields = ctx.blueprint.class.reflections[:default].ordered
        yield ctx
      end

      def around_serialize_object(context)
        res = yield context
        res[:n] += 1 if res[:n]
        res
      end

      def pre_render(object, _blueprint, _view, _options)
        foo = object[:foo]
        { foo: "#{foo} 1" }
      end
    end
  end
  let(:ext2) do
    Class.new(Blueprinter::Extension) do
      attr_reader :log

      def initialize = @log = []

      def around_blueprint_init(ctx)
        log << 'around_blueprint_init'
        ctx.fields = ctx.blueprint.class.reflections[:default].ordered.reverse
        yield ctx
      end

      def pre_render(object, _blueprint, _view, _options)
        foo = object[:foo]
        { foo: "#{foo} 2" }
      end
    end
  end

  context '#registered?' do
    it 'knows whether it contains certain hooks' do
      hooks = described_class.new [ext1.new, ext2.new]
      expect(hooks.registered? :around_serialize_object).to be true
      expect(hooks.registered? :around_blueprint_init).to be true
      expect(hooks.registered? :around_result).to be false
    end
  end

  context '#reduce_hook' do
    it 'returns the final value' do
      hooks = described_class.new [ext1.new, ext2.new, ext1.new, ext1.new]
      result = hooks.reduce_hook(:pre_render, object) do |obj|
        [obj, 'blueprint', 'view', {}]
      end
      expect(result[:foo]).to eq 'Foo 1 2 1 1'
    end

    it 'expands a returned array into args' do
      hooks = described_class.new [ext1.new, ext2.new, ext1.new, ext1.new]
      result = hooks.reduce_hook(:pre_render, object) do |obj|
        [obj, 'blueprint', 'view', {}]
      end
      expect(result[:foo]).to eq 'Foo 1 2 1 1'
    end

    it 'returns the initial value if there are no hooks' do
      hooks = described_class.new []
      ctx = object_ctx.new(serializer.blueprint, serializer.fields, {}, object)
      result = hooks.reduce_hook(:pre_render, ctx.object) { |val| ctx.object = val; ctx }
      expect(result[:foo]).to eq 'Foo'
    end
  end

  context '#around' do
    let(:ext_a) do
      Class.new(Blueprinter::Extension) do
        def initialize(log)
          @log = log
        end

        def around_serialize_object(ctx)
          @log << "A: #{ctx.object[:n]}"
          ctx.object = { n: ctx.object[:n] + 1 }
          res = yield ctx
          @log << "A END"
          res
        end
      end
    end

    let(:ext_b) do
      Class.new(ext_a) do
        def around_serialize_object(ctx)
          @log << "B: #{ctx.object[:n]}"
          ctx.object = { n: ctx.object[:n] + 1 }
          res = yield ctx
          @log << "B END"
          res
        end
      end
    end

    let(:ext_c) do
      Class.new(ext_a) do
        def around_serialize_object(ctx)
          @log << "C: #{ctx.object[:n]}"
          ctx.object = { n: ctx.object[:n] + 1 }
          res = yield ctx
          @log << "C END"
          res
        end
      end
    end

    let(:cache_ext) do
      Class.new(ext_a) do
        def around_serialize_object(ctx)
          @log << "Cache: #{ctx.object[:n]}"
          res =  { n: 42 }
          @log << "Cache END"
          res
        end
      end
    end

    it 'runs nested hooks' do
      log = []
      extensions = [ext_a.new(log), ext_b.new(log), ext_c.new(log)]
      ctx = object_ctx.new(serializer.blueprint, serializer.fields, {}, { n: 0 })
      hooks = described_class.new extensions
      res = hooks.around(:around_serialize_object, ctx) do |ctx|
        log << 'INNER'
        ctx.object
      end
      expect(log).to eq ['A: 0', 'B: 1', 'C: 2', 'INNER', 'C END', 'B END', 'A END']
      expect(res).to eq({ n: 3 })
    end

    it 'runs with no hooks' do
      log = []
      extensions = []
      ctx = object_ctx.new(serializer.blueprint, serializer.fields, {}, { n: 0 })
      hooks = described_class.new extensions
      res = hooks.around(:around_serialize_object, ctx) do |ctx|
        log << 'INNER'
        ctx.object
      end
      expect(log).to eq ['INNER']
      expect(res).to eq({ n: 0 })
    end

    it 'returns early when not yielding' do
      log = []
      extensions = [ext_a.new(log), ext_b.new(log), cache_ext.new(log), ext_c.new(log)]
      ctx = object_ctx.new(serializer.blueprint, serializer.fields, {}, { n: 0 })
      hooks = described_class.new extensions
      res = hooks.around(:around_serialize_object, ctx) do |ctx|
        log << 'INNER'
        ctx.object
      end
      expect(log).to eq ['A: 0', 'B: 1', 'Cache: 2', 'Cache END', 'B END', 'A END']
      expect(res).to eq({ n: 42 })
    end

    it 'bypasses parent hooks with a skip in a nested hook' do
      log = []
      ext = Class.new(Blueprinter::Extension) do
        def around_serialize_object(_ctx) = skip
      end
      extensions = [ext_a.new(log), ext_b.new(log), ext.new, ext_c.new(log)]
      ctx = object_ctx.new(serializer.blueprint, serializer.fields, {}, { n: 0 })
      hooks = described_class.new extensions
      res = hooks.around(:around_serialize_object, ctx) do |ctx|
        log << 'INNER'
      end
      expect(log).to eq ['A: 0', 'B: 1']
      expect(res).to be skip_field
    end

    it 'bypasses parent hooks with a skip in inner block' do
      log = []
      extensions = [ext_a.new(log), ext_b.new(log), ext_c.new(log)]
      ctx = object_ctx.new(serializer.blueprint, serializer.fields, {}, { n: 0 })
      hooks = described_class.new extensions
      res = hooks.around(:around_serialize_object, ctx) do |ctx|
        log << 'INNER'
        throw skip_field, skip_field
      end
      expect(log).to eq ['A: 0', 'B: 1', 'C: 2', 'INNER']
      expect(res).to be skip_field
    end

    it 'requires that the yielded arg is the same class as the method arg' do
      ext = Class.new(Blueprinter::Extension) do
        def around_serialize_object(_ctx) = yield "oops"
      end

      ctx = object_ctx.new(serializer.blueprint, serializer.fields, {}, { n: 0 })
      hooks = described_class.new [ext.new]
      expect do
        hooks.around(:around_serialize_object, ctx, &:object)
      end.to raise_error(Blueprinter::Errors::ExtensionHook, /should yield `#{object_ctx}` but yielded `/)
    end
  end

  context '#around_hook' do
    let(:ext1) do
      Class.new(Blueprinter::Extension) do
        def initialize(log) = @log = log

        def around_serialize_object(ctx)
          @log << 'around_serialize_object: A'
          res = yield ctx
          @log << 'around_serialize_object: B'
          res
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
      hooks = described_class.new [ext1.new(log)]

      ctx = object_ctx.new(serializer.blueprint, serializer.fields, {}, object)
      res = hooks.around(:around_serialize_object, ctx) do |ctx|
        log << 'INNER'
        ctx.object
      end

      expect(log).to eq [
        "around_hook(#{ext1.name}#around_serialize_object): A",
        'around_serialize_object: A',
        'INNER',
        'around_serialize_object: B',
        "around_hook(#{ext1.name}#around_serialize_object): B"
      ]
      expect(res).to eq({ foo: 'Foo' })
    end

    it 'is skipped for hidden extensions' do
      ext1.class_eval { def hidden? = true }
      log = []
      ctx = field_ctx.new(serializer.blueprint, serializer.fields, {}, { foo: 'Foo' }, field, 42)
      hooks = described_class.new [ext1.new(log)]

      res = hooks.around(:around_serialize_object, ctx) do |ctx|
        log << 'INNER'
        ctx.object
      end
      expect(log).to eq [
        'around_serialize_object: A',
        'INNER',
        'around_serialize_object: B',
      ]
      expect(res).to eq({ foo: 'Foo' })
    end

    it 'must yield' do
      ext = Class.new(Blueprinter::Extension) do
        def around_hook(ctx) = nil
      end
      log = []
      ctx = field_ctx.new(serializer.blueprint, serializer.fields, {}, { foo: 'Foo' }, field, 42)
      hooks = described_class.new [ext1.new(log), ext.new]

      expect do
        hooks.around(:around_serialize_object, ctx, &:object)
      end.to raise_error(Blueprinter::Errors::ExtensionHook, /did not yield/)
    end
  end
end
