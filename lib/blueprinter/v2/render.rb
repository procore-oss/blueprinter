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
      def to_hash = to :hash

      # Serialize the object to a JSON string
      # @param _arg Ignored (Rails controller compatibility)
      # @return [String]
      def to_json(_arg = nil) = to :json

      # Serialize the object to the given format
      # @param format [Symbol] Only :json and :hash are supported out of the box. Extensions may add support for others,
      # or change the way :json and :hash behave.
      # @return [Object]
      def to(format)
        serializer = @instances.serializer(@blueprint, @options, 1)
        ctx = Context::Result.new(serializer.blueprint, serializer.fields, @options, @object, format)
        result = serializer.hooks.around(:around_result, ctx) do |new_ctx|
          if new_ctx.blueprint != serializer.blueprint
            blueprint = new_ctx.blueprint
            render = Render.new(new_ctx.object, new_ctx.options, blueprint:, collection: @collection, instances: @instances)
            return render.to new_ctx.format
          end

          @object = new_ctx.object
          serializer.options = new_ctx.options
          serialize serializer
        end
        result.is_a?(Context::Final) ? result.value : result
      end

      alias to_h to_hash

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
