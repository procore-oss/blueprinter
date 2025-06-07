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
      attr_reader :blueprint, :options, :instances, :formatter, :hooks, :defaults, :cond

      # @param options [Hash] Options passed from the callsite
      def initialize(blueprint, options, instances)
        @blueprint = blueprint
        @options = options
        @instances = instances
        @formatter = Formatter.new(blueprint)
        @hooks = Hooks.new([
          Extensions::Core::Prelude.new,
          Extensions::Core::Extractor.new,
          *blueprint.extensions.map { |ext| instances.extension ext },
          Extensions::Core::Postlude.new
        ])
        # "Unroll" these hooks for a significant speed boost
        @defaults = Extensions::Core::Defaults.new
        @cond = Extensions::Core::Conditionals.new
        find_used_hooks!
      end

      #
      # Serialize a single object to a Hash.
      #
      # @param object [Object] The object to serialize
      # @return [Hash] The serialized object
      #
      def object(object)
        @fields ||= prepare!
        if @run_around_object
          ctx = Context::Object.new(instances.blueprint(blueprint), options, object)
          hooks.around(:around_object_serialization, ctx) { serialize(object, @fields, options) }
        else
          serialize(object, @fields, options)
        end
      end

      #
      # Serialize a collection of objects to a Hash.
      #
      # @param collection [Object] The collection to serialize
      # @return [Array<Hash>] The serialized objects
      #
      def collection(collection)
        @fields ||= prepare!
        if @run_around_collection
          ctx = Context::Object.new(instances.blueprint(blueprint), options, collection)
          hooks.around(:around_collection_serialization, ctx) do
            collection.map { |object| serialize(object, @fields, options) }.to_a
          end
        else
          collection.map { |object| serialize(object, @fields, options) }.to_a
        end
      end

      private

      # rubocop:disable Metrics/MethodLength
      def serialize(object, fields, options)
        if @run_blueprint_input
          ctx = Context::Object.new(instances.blueprint(blueprint), options, object)
          object = hooks.reduce_into(:blueprint_input, ctx, :object)
        end

        ctx = Context::Field.new(instances.blueprint(blueprint), options, object, nil, nil)
        result = fields.each_with_object({}) do |field_conf, acc|
          ctx.field = field_conf.field
          ctx.value = nil
          ctx.value = ctx.field.value_proc ? proc_value(ctx) : hooks.call(field_conf.extractor, :extract_value, ctx)
          field_conf.serialize(ctx, acc)
        end

        if @run_blueprint_output
          ctx = Context::Result.new(ctx.blueprint, options, object, result)
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

      # Allow extensions to do time-saving prep work on the current context
      def prepare!
        ctx = Context::Render.new(instances.blueprint(blueprint), options)
        prepared_exts = {}.compare_by_identity
        fields = hooks.last(:blueprint_fields, ctx).map { |field| prepare_field(field, prepared_exts) }.freeze
        defaults.prepare ctx
        cond.prepare ctx
        hooks.run(:prepare, ctx)
        fields
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def prepare_field(field, prepared_exts)
        ext = field.options[:extractor]
        extractor = ext ? instances.extension(ext) : hooks.last_with(:extract_value)
        prepared_exts[extractor] ||= extractor.prepare(ctx) || true if extractor.respond_to?(:prepare)

        case field
        when Fields::Field
          FieldSerializer::Field.new(field, extractor, self)
        when Fields::Object
          FieldSerializer::Object.new(field, extractor, self)
        when Fields::Collection
          FieldSerializer::Collection.new(field, extractor, self)
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      # We save a lot of time by skipping hooks that aren't used
      def find_used_hooks!
        @run_around_object = hooks.registered? :around_object_serialization
        @run_around_collection = hooks.registered? :around_collection_serialization
        @run_blueprint_input = hooks.registered? :blueprint_input
        @run_blueprint_output = hooks.registered? :blueprint_output
      end
    end
  end
end
