# frozen_string_literal: true

require 'blueprinter/v2/instance_cache'

module Blueprinter
  module V2
    class Render
      def initialize(object, options, serializer:, collection:)
        @object = object
        @options = options.dup.freeze
        @serializer = serializer
        @collection = collection
      end

      # Serialize the object to a Hash
      # @return [Hash]
      def to_hash
        ctx = create_context
        @serializer.hooks.around(:around_render, ctx) do
          serialize ctx
        end
      end

      # Serialize the object to a JSON string
      # @return [String]
      def to_json(_arg = nil)
        ctx = create_context
        @serializer.hooks.around(:around_render, ctx) do
          serialize ctx
          @serializer.hooks.first(:json, ctx)
        end
      end

      alias_method :to_h, :to_hash
      alias_method :to_s, :to_json
      alias_method :to_str, :to_json

      private

      # Serializes ctx.object into ctx.value
      def serialize(ctx)
        pre_hook = @collection ? :input_collection : :input_object
        @serializer.hooks.reduce_into(pre_hook, ctx, :object)

        ctx.value =
          if @collection
            @serializer.collection(ctx.object, @options, ctx.instances, ctx.store)
          else
            @serializer.object(ctx.object, @options, ctx.instances, ctx.store)
          end

        post_hook = @collection ? :output_collection : :output_object
        @serializer.hooks.reduce_into(post_hook, ctx, :value)
      end

      def create_context
        instances = InstanceCache.new
        blueprint = instances[@serializer.blueprint]
        Context.new(blueprint, nil, nil, @object, @options, instances, {})
      end
    end
  end
end
