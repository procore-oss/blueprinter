# frozen_string_literal: true

require 'blueprinter/v2/extension'

module Blueprinter
  module V2
    # An interface for running extension hooks
    class Hooks
      def initialize(extensions)
        @hooks = Extension.public_instance_methods(false).each_with_object({}) do |hook, acc|
          acc[hook] = extensions.
            select { |ext| ext.class.public_instance_methods(false).include? hook }.
            map { |ext| ext.public_method(hook) }
        end
      end

      # Return true if any of "hook" returns truthy
      def any?(hook, *args)
        @hooks.fetch(hook).any? { |h| h.call(*args) }
      end

      # Reduce the initial value (plus args) through all instances of "hook"
      def reduce(hook, initial_val)
        @hooks.fetch(hook).reduce(initial_val) do |acc, h|
          args = yield acc
          args.is_a?(Array) ? h.call(*args) : h.call(args)
        end
      end
    end
  end
end
