# frozen_string_literal: true

require 'blueprinter/v2/serializer'
require 'blueprinter/v2/instance_cache'

module Blueprinter
  module V2
    class Render
      def initialize(object, options, blueprint:, collection:)
        @object = object
        @options = options.dup.freeze
        @blueprint = blueprint
        @collection = collection
        @around_hook = collection ? :around_collection_render : :around_object_render
        @input_hook = collection ? :input_collection : :input_object
        @output_hook = collection ? :output_collection : :output_object
      end

      # Serialize the object to a Hash or array of Hashes
      # @return [Hash|Array<Hash>]
      def to_hash
        instances = InstanceCache.new
        ctx = create_context instances
        serializer = instances[Serializer, [@blueprint, @options, instances]]
        serializer.hooks.around(@around_hook, ctx) do
          serialize(serializer, ctx).result
        end
      end

      # Serialize the object to a JSON string
      # @return [String]
      def to_json(_arg = nil)
        instances = InstanceCache.new
        ctx = create_context instances
        serializer = instances[Serializer, [@blueprint, @options, instances]]
        serializer.hooks.around(@around_hook, ctx) do
          result_ctx = serialize(serializer, ctx)
          serializer.hooks.last(:json, result_ctx)
        end
      end

      alias to_h to_hash
      alias to_s to_json
      alias to_str to_json

      private

      # @param ctx [Blueprinter::V2::Context::Object]
      # @return [Blueprinter::V2::Context::Result]
      def serialize(serializer, ctx)
        serializer.hooks.reduce_into(@input_hook, ctx, :object)
        result = @collection ? serializer.collection(ctx.object) : serializer.object(ctx.object)
        Context::Result.new(ctx.blueprint, ctx.options, ctx.object, result).tap do |context|
          serializer.hooks.reduce_into(@output_hook, context, :result)
        end
      end

      # @return [Blueprinter::V2::Context::Object]
      # @return [Blueprinter::V2::InstanceCache]
      def create_context(instances)
        blueprint = instances[@blueprint]
        Context::Object.new(blueprint, @options, @object)
      end
    end
  end
end
