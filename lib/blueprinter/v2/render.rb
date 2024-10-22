# frozen_string_literal: true

require 'blueprinter/v2/instance_cache'

module Blueprinter
  module V2
    class Render
      def initialize(object, options, serializer:, collection:)
        @object = object
        @options = options
        @serializer = serializer
        @collection = collection
      end

      def to_hash
        instance_cache = InstanceCache.new
        blueprint = instance_cache[@serializer.blueprint]
        object = @serializer.hooks.reduce(:input, @object) { |obj| [blueprint, obj, @options] }

        result =
          if @collection
            object.each.map { |obj| @serializer.call(obj, @options, instance_cache) }
          else
            @serializer.call(object, @options, instance_cache)
          end

        @serializer.hooks.reduce(:output, result) { |res| [blueprint, res, @options] }
      end

      def to_json
        # TODO MultiJson.dump to_hash
        to_hash.to_json
      end
    end
  end
end
