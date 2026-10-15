# frozen_string_literal: true

module Blueprinter
  # An interface for running extension hooks efficiently
  # @!visibility private
  class Hooks
    # @param extensions [Array<Blueprinter::Extension>] The extensions we're going to run
    def initialize(extensions)
      @hooks = Extension::HOOKS.to_h { |hook| [hook, []] }
      extensions.each do |ext|
        ext.finalize_hooks.each { |hook| @hooks[hook.name] << hook }
        # V1 doesn't have to register its hooks
        @hooks[:pre_render] << Extension::Hook.new(:pre_render, ext, :pre_render).freeze if ext.respond_to?(:pre_render)
      end
      @hooks.freeze
      @hooks.each(&:freeze)
      @hook_around_hook = registered? :around_hook
      @around_hooks = @hooks[:around_hook]
    end

    #
    # Checks if any hooks of the given name are registered.
    #
    # @param hook [Symbol] Name of hook to call
    # @return [True | False]
    #
    def registered?(hook)
      @hooks.fetch(hook).any?
    end

    # Return all hooks of name `hook`. NOTE: Only needed for V1
    def [](hook) = @hooks.fetch(hook)

    #
    # Runs nested hooks that may yield to further hooks/Blueprinter core. A block MUST be passed,
    # and will run at the innermost yield (if reached).
    #
    # Each hook must yield a context object for the next hook to use.
    #
    # @param hook [Symbol] Name of hook to call
    # @param ctx [Blueprinter::V2::Context] The argument to the hooks
    # @param require_yield [True | False] Throw an exception if a hook doesn't yield
    # @return [Object] Object returned from the outer hook (or from the given block, if there are no hooks)
    #
    def around(hook, ctx, require_yield: false, &)
      hooks = @hooks.fetch(hook)
      if !@hook_around_hook && !require_yield
        _around_direct(hooks, 0, ctx, ctx.class, &)
      else
        _around(hooks, 0, ctx, ctx.class, require_yield:, &)
      end
    end

    private

    # Fast path: no around_hook wrapping, no require_yield
    def _around_direct(hooks, idx, ctx, klass, &)
      hook = hooks[idx]
      return yield ctx if hook.nil?

      hook.ext.public_send(hook.target, ctx) do |yctx|
        unless yctx.is_a?(klass)
          msg = "should yield `#{klass.name}` but yielded `#{yctx.inspect}`"
          raise Errors::ExtensionHook.new(hook.ext, hook.name, hook.target, msg)
        end

        _around_direct(hooks, idx + 1, yctx || ctx, klass, &)
      end
    end

    # Runs hooks recursively
    def _around(hooks, idx, ctx, expected_yield, require_yield: false, &)
      hook = hooks[idx]
      return yield ctx if hook.nil?

      yielded = false
      result = call(hook, ctx) do |yielded_ctx|
        yielded ||= true
        unless yielded_ctx.is_a? expected_yield
          msg = "should yield `#{expected_yield.name}` but yielded `#{yielded_ctx.inspect}`"
          raise Errors::ExtensionHook.new(hook.ext, hook.name, hook.target, msg)
        end

        ctx = yielded_ctx if yielded_ctx
        _around(hooks, idx + 1, ctx, expected_yield, require_yield:, &)
      end
      raise Errors::ExtensionHook.new(hook.ext, hook.name, hook.target, 'did not yield') if require_yield && !yielded

      result
    end

    # Calls a hook on an extension. If the `around_hook` hook is registered it's wrapped around the call.
    def call(hook, ctx, &)
      return hook.ext.public_send(hook.target, ctx, &) if !@hook_around_hook || hook.ext.hidden? || hook.name == :around_hook

      # Hacky, but re-using this context object saves tons of time
      hook_ctx = Thread.current[:_blueprinter_hook_ctx] ||= V2::Context::Hook.new
      hook_ctx.blueprint = ctx.blueprint
      hook_ctx.fields = ctx.fields
      hook_ctx.options = ctx.options
      hook_ctx.extension = hook.ext
      hook_ctx.target = hook.target
      hook_ctx.hook = hook.name
      hook_ctx.store = ctx.store
      hook_ctx.depth = ctx.depth
      result = nil
      _around(@around_hooks, 0, hook_ctx, NilClass, require_yield: true) do
        # return the inner hook's value, not around_hook's
        result = hook.ext.public_send(hook.target, ctx, &)
      end
      result
    end
  end
end
