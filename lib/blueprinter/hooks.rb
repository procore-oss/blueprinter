# frozen_string_literal: true

module Blueprinter
  # An interface for running extension hooks efficiently
  class Hooks
    # @param extensions [Array<Blueprinter::Extension>] The extensions we're going to run
    def initialize(extensions)
      @hooks = Extension.
        public_instance_methods(false).
        each_with_object({}) do |hook, acc|
          acc[hook] = extensions.select { |ext| ext.class.public_instance_methods(false).include? hook }
        end
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
    # @param arg [Object] Argument to hook
    #
    def each(hook, arg)
      @hooks.fetch(hook).each { |ext| call(ext, hook, arg) }
    end

    #
    # Return true if any of "hook" returns truthy.
    #
    # @param hook [Symbol] Name of hook to call
    # @param arg [Object] Argument to hook
    # @return [Boolean]
    #
    def any?(hook, arg)
      @hooks.fetch(hook).any? { |ext| call(ext, hook, arg) }
    end

    #
    # Run only the first-added instance of the hook.
    #
    # @param hook [Symbol] Name of hook to call
    # @param *args Any args for the hook
    # @return The hook return value, or nil if there was no hook
    #
    def first(hook, *args)
      ext = @hooks.fetch(hook).first
      ext ? call(ext, hook, *args) : nil
    end

    #
    # Run only the last-added instance of the hook.
    #
    # @param hook [Symbol] Name of hook to call
    # @param *args Any args for the hook
    # @return The hook return value, or nil if there was no hook
    #
    def last(hook, *args)
      ext = @hooks.fetch(hook).last
      ext ? call(ext, hook, *args) : nil
    end

    #
    # Call the hooks in series, passing the output of one to the block, which returns the args for the next.
    #
    # If the hook requires multiple arguments, the block should return an array.
    #
    # @param hook [Symbol] Name of hook to call
    # @param initial_value [Object] The starting value for the block
    # @return [Object] The last hook's return value
    #
    def reduce(hook, initial_value)
      @hooks.fetch(hook).reduce(initial_value) do |val, ext|
        args = yield val
        args.is_a?(Array) ? call(ext, hook, *args) : call(ext, hook, args)
      end
    end

    #
    # An optimized version of reduce for hooks that are in the hot path. It accepts a
    # Blueprinter::V2::Context and returns an attribute from it.
    #
    # @param hook [Symbol] Name of hook to call
    # @param target_obj [Object] The argument to the hooks (usually a Blueprinter::V2::Context)
    # @param target_attr [Symbol] The attribute on target_obj to update with the hook return value
    # @return [Object] The last hook's return value
    #
    def reduce_into(hook, target_obj, target_attr)
      @hooks.fetch(hook).each do |ext|
        target_obj[target_attr] = call(ext, hook, target_obj)
      end
      target_obj[target_attr]
    end

    #
    # Runs nested hooks that yield. A block MUST be passed, and it will be run at the "apex" of
    # the nested hooks.
    #
    # @param hook [Symbol] Name of hook to call
    # @param args [Object] Arguments to hook
    # @return [Object] The return value from the block passed to this method
    #
    def around(hook, *args)
      result = nil
      @hooks.fetch(hook).reverse.reduce(-> { result = yield }) do |f, ext|
        proc do
          yields = 0
          call(ext, hook, *args) { yields += 1; f.call }
          raise BlueprinterError, "Extension hook '#{ext.class.name}##{hook}' should have yielded 1 time, but yielded #{yields} times" if yields != 1
        end
      end.call
      result
    end

    private

    def call(ext, hook, *args, &block)
      return ext.public_send(hook, *args, &block) if !registered?(:around_hook) || ext.hidden? || hook == :around_hook

      around(:around_hook, ext, hook) do
        ext.public_send(hook, *args, &block)
      end
    end
  end
end
