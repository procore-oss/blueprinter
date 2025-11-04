# frozen_string_literal: true

require 'blueprinter/hooks'
require 'blueprinter/v2/formatter'
require 'blueprinter/v2/field_serializers/field'
require 'blueprinter/v2/field_serializers/object'
require 'blueprinter/v2/field_serializers/collection'
require 'blueprinter/v2/extensions/core/defaults'
require 'blueprinter/v2/extensions/core/conditionals'
require 'blueprinter/v2/extensions/core/json'
require 'blueprinter/v2/extensions/core/wrapper'

module Blueprinter
  module V2
    #
    # The serializer for a given Blueprint. Takes in an object with options and serializes it to a Hash.
    #
    # NOTE: The instance is re-used for the duration of the render.
    #
    class Serializer
      SKIP = :_blueprinter_skip_field

      attr_reader :blueprint, :fields, :options, :instances, :formatter, :hooks, :defaults, :conditionals

      # @param options [Hash] Options passed from the callsite
      def initialize(blueprint_class, options, instances, initial_depth:)
        @blueprint = instances.blueprint(blueprint_class)
        @options = options
        @instances = instances
        @formatter = Formatter.new(blueprint.class)
        @hooks = Hooks.new(extensions)
        @defaults = Extensions::Core::Defaults.new
        @conditionals = Extensions::Core::Conditionals.new
        @fields = @blueprint.class.reflections[:default].ordered
        @field_serializers = blueprint_init initial_depth
        find_used_hooks!
      end

      #
      # Serialize a single object to a Hash.
      #
      # @param object [Object] The object to serialize
      # @return [Hash] The serialized object
      #
      def object(object, depth:)
        if @hook_around_serialize_object
          ctx = Context::Object.new(@blueprint, @fields, @options, object, depth)
          @hooks.around(:around_serialize_object, ctx) do |ctx|
            serialize_object(ctx.object, depth:)
          end
        else
          serialize_object(object, depth:)
        end
      end

      #
      # Serialize a collection of objects to a Hash.
      #
      # @param collection [Enumerable] The collection to serialize
      # @return [Enumerable] The serialized hashes
      #
      def collection(collection, depth:)
        if @hook_around_serialize_collection
          ctx = Context::Object.new(@blueprint, @fields, @options, collection, depth)
          @hooks.around(:around_serialize_collection, ctx) do |ctx|
            ctx.object.map { |object| serialize_object(object, depth:) }.to_a
          end
        else
          collection.map { |object| serialize_object(object, depth:) }.to_a
        end
      end

      private

      def serialize_object(object, depth:)
        if @hook_around_blueprint
          ctx = Context::Object.new(@blueprint, @fields, @options, object, depth)
          @hooks.around(:around_blueprint, ctx) do |ctx|
            serialize(ctx.object, depth:)
          end
        else
          serialize(object, depth:)
        end
      end

      def serialize(object, depth:)
        ctx = Context::Field.new(@blueprint, @fields, @options, object, nil, depth)
        @field_serializers.each_with_object({}) do |field_conf, acc|
          ctx.field = field_conf.field
          field_conf.serialize(ctx, acc)
        end
      end

      def extensions
        extensions = @blueprint.class.extensions.map { |ext| @instances.extension ext }
        [*extensions, Extensions::Core::Json.new, Extensions::Core::Wrapper.new]
      end

      # Allow extensions to do time-saving prep work on the current context
      def blueprint_init(depth)
        ctx = Context::Render.new(@blueprint, fields, @options, depth)
        @conditionals.around_blueprint_init ctx
        @defaults.around_blueprint_init ctx
        @hooks.around(:around_blueprint_init, ctx, require_yield: true) do |ctx|
          @options = ctx.options
          @fields = ctx.fields
        end
        @fields.map { |field| field_serializer field }.freeze
      end

      def field_serializer(field)
        case field.type
        when :field
          FieldSerializers::Field.new(field, self)
        when :object
          FieldSerializers::Object.new(field, self)
        when :collection
          FieldSerializers::Collection.new(field, self)
        end
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
