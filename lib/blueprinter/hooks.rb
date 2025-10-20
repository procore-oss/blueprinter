# frozen_string_literal: true

module Blueprinter
  # An interface for running extension hooks efficiently
  class Hooks
    # @param extensions [Array<Blueprinter::Extension>] The extensions we're going to run
    def initialize(extensions)
      @hooks = Extension::HOOKS.each_with_object({}) { |hook, acc| acc[hook] = [] }
      extensions.each do |ext|
        ext.class.hooks.each { |hook| @hooks[hook] << ext }
      end
      @hooks.freeze
      @reversed_hooks ||= @hooks.transform_values(&:reverse).freeze
      @around_hook_registered = registered? :around_hook
    end

    #
    # Checks if any hooks of the given name are registered.
    #
    # @param hook [Symbol] Name of hook to call
    # @return [Boolean]
    #
    def registered?(hook)
      @hooks.fetch(hook).any?
    end

    #
    # Runs each hook.
    #
    # @param hook [Symbol] Name of hook to call
    # @param ctx [Blueprinter::V2::Context] The argument to the hooks
    #
    def run(hook, ctx)
      @hooks.fetch(hook).each { |ext| call(ext, hook, ctx) }
    end

    #
    # Run only the first-added instance of the hook.
    #
    # @param hook [Symbol] Name of hook to call
    # @param ctx [Blueprinter::V2::Context] The argument to the hooks
    # @return The hook return value, or nil if there was no hook
    #
    def first(hook, ctx)
      ext = @hooks.fetch(hook).first
      ext ? call(ext, hook, ctx) : nil
    end

    #
    # Run only the last-added instance of the hook.
    #
    # @param hook [Symbol] Name of hook to call
    # @param ctx [Blueprinter::V2::Context] The argument to the hooks
    # @return The hook return value, or nil if there was no hook
    #
    def last(hook, ctx)
      ext = @hooks.fetch(hook).last
      ext ? call(ext, hook, ctx) : nil
    end

    #
    # Returns the last-added extension that implements the given hook.
    #
    # @param hook [Symbol] Name of hook to search for
    # @return [Blueprinter::Extension]
    #
    def last_with(hook) = @hooks.fetch(hook).last

    #
    # DEPRECATED - do not use in V2!
    #
    # Call the hooks in series, passing the output of one to the block, which returns the args for the next.
    #
    # If the hook requires multiple arguments, the block should return an array.
    #
    # @param hook [Symbol] Name of hook to call
    # @param initial_value [Object] The starting value for the block
    # @return [Object] The last hook's return value
    #
    def reduce_hook(hook, initial_value)
      @hooks.fetch(hook).reduce(initial_value) do |val, ext|
        args = yield val
        args.is_a?(Array) ? ext.public_send(hook, *args) : ext.public_send(hook, args)
      end
    end

    #
    # Runs nested hooks that yield. A block MUST be passed, and it will be run at the "apex" of
    # the nested hooks. It's return value will be the final return value.
    #
    # Each hook MUST yield exactly once, or an exception will be raised.
    #
    # @param hook [Symbol] Name of hook to call
    # @param ctx [Blueprinter::V2::Context] The argument to the hooks
    # @yield [Object] "attr" from "ctx" as it's been yielded by hooks. Should return it/new/modified version.
    # @return [Object] Object returned from the given block
    #
    def around(hook, ctx)
      result = nil
      @reversed_hooks.fetch(hook).reduce(-> { result = yield }) do |f, ext|
        proc do
          yields = 0
          call(ext, hook, ctx) do
            yields += 1
            f.call
          end
          if yields != 1
            msg = "Extension hook '#{ext.class.name}##{hook}' should have yielded 1 time, but yielded #{yields} times"
            raise Errors::ExtensionHook.new(ext, hook, msg)
          end
        end
      end.call
      result
    end

    #
    # Runs nested hooks that yield. A block MUST be passed, and it will be run at the "apex" of
    # the nested hooks. It's return value will be passed as the "yield" value to the final hook.
    #
    # Each hook SHOULD yield unless it wants to bypass subseqent hooks and return a final value.
    #
    # @param hook [Symbol] Name of hook to call
    # @param ctx [Blueprinter::V2::Context] The argument to the hooks
    # @yield [Object] "attr" from "ctx" as it's been yielded by hooks. Should return it/new/modified version.
    # @return [Object] Object returned from the outer hook (or from the given block, if there are no hooks)
    #
    def reduce_around(hook, ctx, attr = nil, &inner)
      hooks = @hooks.fetch(hook)
      initial_val = attr.nil? ? nil : ctx[attr]
      catch V2::Serializer::SKIP do
        _reduce_around(hooks, hook, 0, ctx, attr, inner, initial_val)
      end
    end

    def call(ext, hook, ctx, &)
      return ext.public_send(hook, ctx, &) if !@around_hook_registered || ext.hidden? || hook == :around_hook

      hook_ctx = V2::Context::Hook.new(ctx.blueprint, ctx.fields, ctx.options, ext, hook)
      around(:around_hook, hook_ctx) do
        ext.public_send(hook, ctx, &)
      end
    end

    private

    def _reduce_around(hooks, hook, idx, ctx, attr, inner, res)
      #throw res if res == V2::Serializer::SKIP

      ext = hooks[idx]
      return inner ? inner.call(res) : res if ext.nil?

      call(ext, hook, ctx) do |y|
        #throw y if y == V2::Serializer::SKIP
        #next y if y == V2::Serializer::SKIP

        if attr
          ctx = ctx.dup
          ctx[attr] = y
        end
        res = _reduce_around(hooks, hook, idx + 1, ctx, attr, inner, y)
        throw res, res if res == V2::Serializer::SKIP
        res
      end
    end
  end
end
