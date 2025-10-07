# frozen_string_literal: true

require 'blueprinter/v2/serializer'

module Blueprinter
  module V2
    class Render
      def initialize(object, options, blueprint:, collection:, instances:)
        @object = object
        @options = options.dup.freeze
        @blueprint = blueprint
        @instances = instances
        @collection = collection
      end

      # Serialize the object to a Hash or array of Hashes
      # @return [Hash|Array<Hash>]
      def to_hash
        serializer = @instances.serializer(@blueprint, @options, 1)
        serialize serializer
      end

      # Serialize the object to a JSON string
      # @return [String]
      def to_json(_arg = nil)
        serializer = @instances.serializer(@blueprint, @options, 1)
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
