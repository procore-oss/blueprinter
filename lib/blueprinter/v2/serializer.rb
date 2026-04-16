# frozen_string_literal: true

require 'blueprinter/hooks'
require 'blueprinter/v2/conditionals'
require 'blueprinter/v2/defaults'
require 'blueprinter/v2/field_serializer'

module Blueprinter
  module V2
    #
    # The serializer for a given Blueprint. Takes in an object with options and serializes it to a Hash.
    #
    # NOTE: The instance lives for the duration of your application.
    #
    class Serializer
      SIGNAL = :_blueprinter_signal
      SIG_SKIP = :_blueprinter_skip
      Config = Struct.new(:blueprint, :fields, :options, :obj_ctx, :parent_ctx, :conditionals, :defaults, keyword_init: true)

      attr_reader :blueprint_class, :hooks

      def initialize(blueprint_class)
        @blueprint_class = blueprint_class
        @hooks = Hooks.new(extensions)
        @field_serializer = FieldSerializer.new(blueprint_class, @hooks)
        find_used_hooks!
      end

      def object(object, options, instances:, store:, depth:, parent: nil)
        config = store[@blueprint_class.object_id] ||= blueprint_init(options, instances:, store:, depth:)
        if @hook_around_serialize_object
          config.obj_ctx.object = object
          config.obj_ctx.parent = parent
          config.obj_ctx.depth = depth
          @hooks.around(:around_serialize_object, config.obj_ctx) do |ctx|
            serialize(config, ctx.object, parent:, instances:, store:, depth:)
          end
        else
          serialize(config, object, parent:, instances:, store:, depth:)
        end
      end

      def collection(objects, options, instances:, store:, depth:, parent: nil)
        config = store[@blueprint_class.object_id] ||= blueprint_init(options, instances:, store:, depth:)
        if @hook_around_serialize_collection
          config.obj_ctx.object = objects
          config.obj_ctx.parent = parent
          config.obj_ctx.depth = depth
          @hooks.around(:around_serialize_collection, config.obj_ctx) do |ctx|
            ctx.object.map { |object| serialize(config, object, parent:, instances:, store:, depth:) }
          end
        else
          objects.map { |object| serialize(config, object, parent:, instances:, store:, depth:) }
        end
      end

      def fields
        @_fields ||= blueprint_class.reflections[:default].ordered
      end

      private

      def serialize(config, object, parent:, instances:, store:, depth:)
        if @hook_around_blueprint
          config.obj_ctx.object = object
          config.obj_ctx.parent = parent
          config.obj_ctx.depth = depth
          @hooks.around(:around_blueprint, config.obj_ctx) do |ctx|
            @field_serializer.serialize(config, ctx.object, instances:, store:, depth:)
          end
        else
          @field_serializer.serialize(config, object, instances:, store:, depth:)
        end
      end

      def blueprint_init(options, instances:, store:, depth:)
        blueprint = instances.blueprint(blueprint_class)
        conditionals = Conditionals.new(blueprint, options)
        defaults = Defaults.new(blueprint, options)

        config = Config.new(blueprint:, fields:, options:, conditionals:, defaults:)
        ctx = Context::Render.new(blueprint, fields, options, store, depth)
        @hooks.around(:around_blueprint_init, ctx, require_yield: true) do |ctx|
          config.options = ctx.options.freeze
          config.fields = ctx.fields.freeze
          # cheaper to create these once per render and re-use
          config.obj_ctx = Context::Object.new(blueprint, config.fields, config.options, nil, nil, store)
          config.parent_ctx = Context::Parent.new(@blueprint_class)
        end
        config
      end

      def extensions
        extensions = @blueprint_class.extensions.map do |ext|
          case ext
          when Extension then ext
          when Proc then ext.call
          else raise BlueprinterError, 'Extensions must be an instance of Blueprinter::Extension or a Proc that returns one'
          end
        end
        [*extensions, Extensions::Core::Json.new, Extensions::Core::Wrapper.new]
      end

      # We save a lot of time by skipping hooks that aren't used
      def find_used_hooks!
        @hook_around_serialize_object = @hooks.registered? :around_serialize_object
        @hook_around_serialize_collection = @hooks.registered? :around_serialize_collection
        @hook_around_blueprint = @hooks.registered? :around_blueprint
      end
    end
  end
end
