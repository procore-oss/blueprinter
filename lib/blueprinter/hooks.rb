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
    # @return [Object] Object returned from the outer hook (or from the given block, if there are no hooks)
    #
    def around(hook, ctx, &inner)
      hooks = @hooks.fetch(hook)
      catch V2::Serializer::SKIP do
        _around(hooks, hook, 0, ctx, ctx.class, inner)
      end
    end

    private

    def call(ext, hook, ctx, &)
      return ext.public_send(hook, ctx, &) if !@hook_around_hook || ext.hidden? || hook == :around_hook

      result = nil
      hooks = @hooks.fetch(:around_hook)
      hook_ctx = V2::Context::Hook.new(ctx.blueprint, ctx.fields, ctx.options, ext, hook)
      _around(hooks, :around_hook, 0, hook_ctx, NilClass, lambda do |_|
        result = ext.public_send(hook, ctx, &)
      end, required: true)
      result
    end

    def _around(hooks, hook, idx, ctx, expected_yield, inner, required: false)
      ext = hooks[idx]
      return inner.call(ctx) if ext.nil?

      reached = false
      result = call(ext, hook, ctx) do |yielded_ctx|
        reached = true
        unless yielded_ctx.is_a? expected_yield
          msg = "should yield `#{expected_yield.name}` but yielded `#{yielded_ctx.inspect}`"
          raise Errors::ExtensionHook.new(ext, hook, msg)
        end

        ctx = yielded_ctx.dup if yielded_ctx
        _around(hooks, hook, idx + 1, ctx, expected_yield, inner, required:)
      end
      raise Errors::ExtensionHook.new(ext, hook, 'did not yield') if required && !reached

      result
    end
  end
end
