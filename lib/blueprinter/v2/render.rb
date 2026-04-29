# frozen_string_literal: true

require 'blueprinter/v2/serializer'

module Blueprinter
  module V2
    class Render
      attr_accessor :store

      def initialize(object, options, blueprint:, collection:, instances:)
        @object = object
        @options = options.dup.freeze
        @blueprint_class = blueprint
        @serializer = blueprint.serializer
        @instances = instances
        @collection = collection
        @store = {}
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
        blueprint = @instances.blueprint(@blueprint_class)
        result =
          if @serializer.hooks.registered? :around_result
            ctx = Context::Result.new(blueprint, @serializer.default_fields, @options, @object, format, store)
            @serializer.hooks.around(:around_result, ctx) do |new_ctx|
              if new_ctx.blueprint != blueprint
                blueprint = new_ctx.blueprint.is_a?(Class) ? new_ctx.blueprint : new_ctx.blueprint.class
                render = Render.new(new_ctx.object, new_ctx.options, blueprint:, collection: @collection,
                                                                     instances: @instances)
                return render.to new_ctx.format
              end

              @object = new_ctx.object
              @options = new_ctx.options.dup.freeze unless new_ctx.options == @options
              serialize
            end
          else
            serialize
          end
        result.is_a?(Context::Final) ? result.value : result
      end

      alias to_h to_hash

      private

      def serialize
        if @collection
          @serializer.collection(@object, @options, store:, instances: @instances)
        else
          @serializer.object(@object, @options, store:, instances: @instances)
        end
      end
    end
  end
end
