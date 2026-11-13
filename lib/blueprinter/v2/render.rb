# frozen_string_literal: true

require 'blueprinter/v2/serializer'

module Blueprinter
  module V2
    #
    # Represents a pending Blueprint render. Used internally by {Blueprinter::V2::Rendering#render render},
    # {Blueprinter::V2::Rendering#render_object render_object}, and
    # {Blueprinter::V2::Rendering#render_collection render_collection}; never returned to callers.
    #
    # @!visibility private
    #
    class Render
      # @param object [Object] The object (or collection) to render
      # @param options [Hash] Options passed to `render` (will be frozen; pass a copy you own)
      # @param blueprint [Class] The Blueprint class to use
      # @param collection [true | false] True of `object` is Enumerable
      # @param instances [Blueprinter::V2::InstanceCache] Instance cache to use during this render
      def initialize(object, options, blueprint:, collection:, instances:)
        @object = object
        @options = options
        @blueprint_class = blueprint
        @serializer = blueprint.serializer
        @instances = instances
        @collection = collection
        @store = {}
      end

      # Serialize the object to the given format.
      #
      # Only `:json` and `:hash` are supported out of the box. Extensions may add support for others or alter
      # how `:json` and `:hash` are handled.
      #
      # @param format [Symbol]
      # @return [Object]
      def render(format)
        blueprint = @instances.blueprint(@blueprint_class)
        result =
          if @serializer.hooks.registered? :around_result
            ctx = Context::Result.new(blueprint, @serializer.default_fields, @options, @object, format, @store)
            @serializer.hooks.around(:around_result, ctx) do |new_ctx|
              return rerender(new_ctx) if new_ctx.blueprint != blueprint

              @object = new_ctx.object
              @options = new_ctx.options.dup unless new_ctx.options == @options
              serialize
            end
          else
            serialize
          end
        result.is_a?(Context::Serialized) ? result.value : result
      end

      private

      # Restart the render with the Blueprint, object, options, and format from `ctx`
      def rerender(ctx)
        blueprint = ctx.blueprint.is_a?(Class) ? ctx.blueprint : ctx.blueprint.class
        options = ctx.options == @options ? @options : ctx.options.dup
        Render.new(ctx.object, options, blueprint:, collection: @collection, instances: @instances).render(ctx.format)
      end

      def serialize
        @options.freeze
        if @collection
          @serializer.collection(@object, @options, store: @store, instances: @instances)
        else
          @serializer.object(@object, @options, store: @store, instances: @instances)
        end
      end
    end
  end
end
