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
        @around_hook = collection ? :around_collection_render : :around_object_render
        @input_hook = collection ? :input_collection : :input_object
        @output_hook = collection ? :output_collection : :output_object
      end

      # Serialize the object to a Hash or array of Hashes
      # @return [Hash|Array<Hash>]
      def to_hash
        ctx = create_context
        @serializer.hooks.around(@around_hook, ctx) do
          serialize(ctx).result
        end
      end

      # Serialize the object to a JSON string
      # @return [String]
      def to_json(_arg = nil)
        ctx = create_context
        @serializer.hooks.around(@around_hook, ctx) do
          result_ctx = serialize ctx
          @serializer.hooks.last(:json, result_ctx)
        end
      end

      alias to_h to_hash
      alias to_s to_json
      alias to_str to_json

      private

      # @param ctx [Blueprinter::V2::Context::Object]
      # @return [Blueprinter::V2::Context::Result]
      def serialize(ctx)
        @serializer.hooks.reduce_into(@input_hook, ctx, :object)
        result =
          if @collection
            @serializer.collection(ctx.object, @options, ctx.instances, ctx.store)
          else
            @serializer.object(ctx.object, @options, ctx.instances, ctx.store)
          end
        Context::Result.new(ctx.blueprint, ctx.options, ctx.instances, ctx.store, ctx.object, result).tap do |context|
          @serializer.hooks.reduce_into(@output_hook, context, :result)
        end
      end

      # @return [Blueprinter::V2::Context::Object]
      def create_context
        instances = InstanceCache.new
        blueprint = instances[@serializer.blueprint]
        Context::Object.new(blueprint, @options, instances, {}, @object)
      end
    end
  end
end
