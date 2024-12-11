# frozen_string_literal: true

require 'json' # TODO replace with multi json
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

      def to_hash
        instance_cache = InstanceCache.new
        blueprint = instance_cache[@serializer.blueprint]
        pre_hook = @collection ? :input_collection : :input_object
        post_hook = @collection ? :output_collection : :output_object

        ctx = Context.new(blueprint, nil, nil, @object, @options, instance_cache, {})
        @serializer.hooks.around(:around, ctx) do
          object = @serializer.hooks.reduce_into(pre_hook, ctx, :object)
          ctx.value =
            if @collection
              object.map { |obj| @serializer.call(obj, @options, instance_cache, ctx.store) }
            else
              @serializer.call(object, @options, instance_cache, ctx.store)
            end
          @serializer.hooks.reduce_into(post_hook, ctx, :value)
        end
      end

      def to_json
        # TODO MultiJson.dump to_hash
        to_hash.to_json
      end
    end
  end
end
