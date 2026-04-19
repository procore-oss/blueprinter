# frozen_string_literal: true

module Blueprinter
  # An interface for running extension hooks efficiently
  class Hooks
    # @param extensions [Array<Blueprinter::Extension>] The extensions we're going to run
    def initialize(extensions)
      @hooks = Extension::HOOKS.to_h { |hook| [hook, []] }
      extensions.each do |ext|
        ext.class.hooks.each { |hook| @hooks[hook] << ext }
      end
      @hooks.freeze
      @hook_around_hook = registered? :around_hook
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
    # @param require_yield [Boolean] Throw an exception if a hook doesn't yield
    # @return [Object] Object returned from the outer hook (or from the given block, if there are no hooks)
    #
    def around(hook, ctx, require_yield: false, &)
      hooks = @hooks.fetch(hook)
      _around(hooks, hook, 0, ctx, ctx.class, require_yield:, &)
    end

    private

    def call(ext, hook, ctx, &)
      return ext.public_send(hook, ctx, &) if !@hook_around_hook || ext.hidden? || hook == :around_hook

      result = nil
      hooks = @hooks.fetch(:around_hook)
      hook_ctx = V2::Context::Hook.new(ctx.blueprint, ctx.fields, ctx.options, ext, hook)
      _around(hooks, :around_hook, 0, hook_ctx, NilClass, require_yield: true) do
        result = ext.public_send(hook, ctx, &)
      end
      result
    end

    def _around(hooks, hook, idx, ctx, expected_yield, require_yield: false, &)
      ext = hooks[idx]
      return yield ctx if ext.nil?

      yielded = false
      result = call(ext, hook, ctx) do |yielded_ctx|
        yielded ||= true
        unless yielded_ctx.is_a? expected_yield
          msg = "should yield `#{expected_yield.name}` but yielded `#{yielded_ctx.inspect}`"
          raise Errors::ExtensionHook.new(ext, hook, msg)
        end

        ctx = yielded_ctx if yielded_ctx
        _around(hooks, hook, idx + 1, ctx, expected_yield, require_yield:, &)
      end
      raise Errors::ExtensionHook.new(ext, hook, 'did not yield') if require_yield && !yielded

      result
    end
  end
end
