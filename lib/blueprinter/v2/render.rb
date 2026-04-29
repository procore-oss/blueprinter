# frozen_string_literal: true

require 'blueprinter/v2/serializer'

module Blueprinter
  module V2
    #
    # Represents a pending Blueprint render. Returned by {Blueprinter::V2::Base.render render},
    # {Blueprinter::V2::Base.render_object render_object}, and {Blueprinter::V2::Base.render_collection render_collection}.
    #
    #   render = WidgetBlueprint.render(widget)
    #
    #   # output JSON
    #   render.to_json
    #
    #   # output a Hash
    #   render.to_hash
    #
    #   # output a format added by an extension
    #   render.to :yaml
    #
    class Render
      # @return [Hash] Store available during render. Accessible to extensions, if/unless/default Procs, or field blocks.
      attr_accessor :store

      # @param object [Object] The object (or collection) to render
      # @param options [Hash] Options passed to `render`
      # @param blueprint [Class] The Blueprint class to use
      # @param collection [true | false] True of `object` is Enumerable
      # @param instances [Blueprinter::V2::InstanceCache] Instance cache to use during this render
      # @!visibility private
      def initialize(object, options, blueprint:, collection:, instances:)
        @object = object
        @options = options.dup
        @blueprint_class = blueprint
        @serializer = blueprint.serializer
        @instances = instances
        @collection = collection
        @store = {}
      end

      # Serialize the object to a Hash or array of Hashes
      #
      #   MyBlueprint.render(widget).to_hash
      #
      # @return [Hash|Array<Hash>]
      def to_hash = to :hash

      # Serialize the object to a JSON string
      #
      #   MyBlueprint.render(widget).to_json
      #
      # In Rails controllers you may omit the `to_json` call:
      #
      #   render json: MyBlueprint.render(widget)
      #
      # @param _arg Ignored (Rails controller compatibility)
      # @return [String]
      def to_json(_arg = nil) = to :json

      # Serialize the object to the given format.
      #
      # Only `:json` and `:hash` are supported out of the box. Extensions may add support for others or alter
      # how `:json` and `:hash` are handled.
      #
      # @param format [Symbol]
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
              @options = new_ctx.options.dup unless new_ctx.options == @options
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
        @options.freeze
        if @collection
          @serializer.collection(@object, @options, store:, instances: @instances)
        else
          @serializer.object(@object, @options, store:, instances: @instances)
        end
      end
    end
  end
end
