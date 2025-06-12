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
      end

      # Serialize the object to a Hash or array of Hashes
      # @return [Hash|Array<Hash>]
      def to_hash
        instances = InstanceCache.new
        serializer = instances.serializer(@blueprint, @options, 1)
        serialize serializer
      end

      # Serialize the object to a JSON string
      # @return [String]
      def to_json(_arg = nil)
        instances = InstanceCache.new
        serializer = instances.serializer(@blueprint, @options, 1)
        result = serialize serializer
        ctx = Context::Result.new(serializer.blueprint, serializer.fields, @options, @object, result, 1)
        serializer.hooks.last(:json, ctx)
      end

      alias to_h to_hash
      alias to_s to_json
      alias to_str to_json

      private

      def serialize(serializer)
        if @collection
          serializer.collection(@object, depth: 1)
        else
          serializer.object(@object, depth: 1)
        end
      end
    end
  end
end
