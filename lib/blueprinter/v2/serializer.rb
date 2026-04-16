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
      Config = Struct.new(:blueprint, :fields, :options, :conditionals, :defaults, keyword_init: true)

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
          ctx = Context::Object.new(config.blueprint, config.fields, config.options, object, parent, store, depth)
          @hooks.around(:around_serialize_object, ctx) do |ctx|
            serialize_object(config, ctx.object, parent:, instances:, store:, depth:)
          end
        else
          serialize_object(config, object, parent:, instances:, store:, depth:)
        end
      end

      def collection(objects, options, instances:, store:, depth:, parent: nil)
        config = store[@blueprint_class.object_id] ||= blueprint_init(options, instances:, store:, depth:)
        if @hook_around_serialize_collection
          ctx = Context::Object.new(config.blueprint, config.fields, config.options, objects, parent, store, depth)
          @hooks.around(:around_serialize_collection, ctx) do |ctx|
            serialize_collection(config, ctx.object, parent:, instances:, store:, depth:)
          end
        else
          serialize_collection(config, objects, parent:, instances:, store:, depth:)
        end
      end

      def fields
        @_fields ||= blueprint_class.reflections[:default].ordered
      end

      private

      def serialize_object(config, object, parent:, instances:, store:, depth:)
        if @hook_around_blueprint
          ctx = Context::Object.new(config.blueprint, config.fields, config.options, object, parent, store, depth)
          @hooks.around(:around_blueprint, ctx) do |ctx|
            @field_serializer.serialize(config, ctx.object, instances:, store:, depth:)
          end
        else
          @field_serializer.serialize(config, object, instances:, store:, depth:)
        end
      end

      # Calling `objects.map` inside here is faster than calling this method N times inside of `objects.map`
      def serialize_collection(config, objects, parent:, instances:, store:, depth:)
        ctx =
          if @hook_around_blueprint
            Context::Object.new(config.blueprint, config.fields, config.options, nil, parent, store, depth)
          end
        objects.map do |object|
          if @hook_around_blueprint
            ctx.object = object
            @hooks.around(:around_blueprint, ctx) do |ctx|
              @field_serializer.serialize(config, ctx.object, instances:, store:, depth:)
            end
          else
            @field_serializer.serialize(config, object, instances:, store:, depth:)
          end
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
        end
        config
      end

      def extensions
        extensions = @blueprint_class.extensions.map do |ext|
          case ext
          when Extension then ext
          when Class then ext.new
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
