# frozen_string_literal: true

require 'blueprinter/hooks'
require 'blueprinter/v2/formatter'
require 'blueprinter/v2/field_serializer'

module Blueprinter
  module V2
    #
    # The serializer for a given Blueprint. Takes in an object with options and serializes it to a Hash.
    #
    # NOTE: The instance is re-used for the duration of the render.
    #
    class Serializer
      attr_reader :blueprint, :fields, :field_serializers, :options, :instances, :formatter, :hooks, :defaults, :cond

      # @param options [Hash] Options passed from the callsite
      def initialize(blueprint_class, options, instances, initial_depth:)
        @blueprint = instances.blueprint(blueprint_class)
        @options = options
        @instances = instances
        @formatter = Formatter.new(blueprint.class)
        @hooks = Hooks.new(extensions)
        # "Unroll" these hooks for a significant speed boost
        @defaults = Extensions::Core::Defaults.new
        @cond = Extensions::Core::Conditionals.new
        @fields = blueprint_fields initial_depth
        @field_serializers = blueprint_setup initial_depth
        find_used_hooks!
      end

      #
      # Serialize a single object to a Hash.
      #
      # @param object [Object] The object to serialize
      # @return [Hash] The serialized object
      #
      def object(object, depth:)
        if @run_around_serialize_object
          ctx = Context::Object.new(blueprint, fields, options, object, depth)
          hooks.around(:around_serialize_object, ctx) do
            serialize_object(object, options, depth:)
          end
        else
          serialize_object(object, options, depth:)
        end
      end

      #
      # Serialize a collection of objects to a Hash.
      #
      # @param collection [Enumerable] The collection to serialize
      # @return [Enumerable] The serialized hashes
      #
      def collection(collection, depth:)
        if @run_around_serialize_collection
          ctx = Context::Object.new(blueprint, fields, options, collection, depth)
          hooks.around(:around_serialize_collection, ctx) do
            serialize_collection(collection, options, depth:)
          end
        else
          serialize_collection(collection, options, depth:)
        end
      end

      private

      def serialize_object(object, options, depth:)
        if @run_object_input
          ctx = Context::Object.new(blueprint, fields, options, object, depth)
          object = hooks.reduce_into(:object_input, ctx, :object)
        end

        result = serialize(object, options, depth:)
        return result unless @run_object_output

        ctx = Context::Result.new(blueprint, fields, options, object, result, depth)
        hooks.reduce_into(:object_output, ctx, :result)
      end

      def serialize_collection(collection, options, depth:)
        if @run_collection_input
          ctx = Context::Object.new(blueprint, fields, options, collection, depth)
          collection = hooks.reduce_into(:collection_input, ctx, :object)
        end

        result = collection.map { |object| serialize(object, options, depth:) }.to_a
        return result unless @run_collection_output

        ctx = Context::Result.new(blueprint, fields, options, collection, result, depth)
        hooks.reduce_into(:collection_output, ctx, :result)
      end

      # rubocop:disable Metrics/MethodLength
      def serialize(object, options, depth:)
        if @run_blueprint_input
          ctx = Context::Object.new(blueprint, fields, options, object, depth)
          object = hooks.reduce_into(:blueprint_input, ctx, :object)
        end

        ctx = Context::Field.new(blueprint, fields, options, object, nil, nil, depth)
        result = field_serializers.each_with_object({}) do |field_conf, acc|
          ctx.field = field_conf.field
          ctx.value = nil
          ctx.value = ctx.field.value_proc ? proc_value(ctx) : hooks.call(field_conf.extractor, :extract_value, ctx)
          field_conf.serialize(ctx, acc)
        end

        if @run_blueprint_output
          ctx = Context::Result.new(blueprint, fields, options, object, result, depth)
          hooks.reduce_into(:blueprint_output, ctx, :result)
        else
          result
        end
      end
      # rubocop:enable Metrics/MethodLength

      # @param ctx [Blueprinter::V2::Context::Field]
      def proc_value(ctx)
        ctx.blueprint.instance_exec(ctx, &ctx.field.value_proc)
      end

      def extensions
        extensions = blueprint.class.extensions.map { |ext| instances.extension ext }
        [Extensions::Core::Prelude.new, Extensions::Core::Extractor.new, *extensions, Extensions::Core::Postlude.new]
      end

      def blueprint_fields(depth)
        default_fields = blueprint.class.reflections[:default].ordered
        ctx = Context::Render.new(blueprint, default_fields, options, depth)
        hooks.last(:blueprint_fields, ctx).freeze
      end

      # Allow extensions to do time-saving prep work on the current context
      def blueprint_setup(depth)
        ctx = Context::Render.new(blueprint, fields, options, depth)
        defaults.blueprint_setup ctx
        cond.blueprint_setup ctx
        hooks.run(:blueprint_setup, ctx)
        setup_exts = {}.compare_by_identity
        fields.map { |field| field_serializer(field, setup_exts, ctx) }.freeze
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def field_serializer(field, setup_exts, ctx)
        ext = field.options[:extractor]
        extractor = ext ? instances.extension(ext) : hooks.last_with(:extract_value)
        setup_exts[extractor] ||= extractor.blueprint_setup(ctx) || true if extractor.respond_to?(:blueprint_setup)

        case field.type
        when :field
          FieldSerializer::Field.new(field, extractor, self)
        when :object
          FieldSerializer::Object.new(field, extractor, self)
        when :collection
          FieldSerializer::Collection.new(field, extractor, self)
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      # We save a lot of time by skipping hooks that aren't used
      def find_used_hooks!
        @run_around_serialize_object = hooks.registered? :around_serialize_object
        @run_around_serialize_collection = hooks.registered? :around_serialize_collection
        @run_object_input = hooks.registered? :object_input
        @run_collection_input = hooks.registered? :collection_input
        @run_blueprint_input = hooks.registered? :blueprint_input
        @run_blueprint_output = hooks.registered? :blueprint_output
        @run_object_output = hooks.registered? :object_output
        @run_collection_output = hooks.registered? :collection_output
      end
    end
  end
end
