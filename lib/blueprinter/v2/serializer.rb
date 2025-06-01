# frozen_string_literal: true

require 'blueprinter/hooks'
require 'blueprinter/v2/formatter'
require 'blueprinter/v2/field_serializer'

module Blueprinter
  module V2
    #
    # The serializer for a given Blueprint. Takes in an object with options and serializes it to a Hash.
    #
    # NOTE: Each Blueprint gets a *single* Serializer instance that will live for the duration of the application.
    #
    class Serializer
      attr_reader :blueprint, :formatter, :hooks, :defaults, :cond

      def initialize(blueprint)
        @hooks = Hooks.new([
          Extensions::Core::Prelude.new,
          Extensions::Core::Extractor.new,
          *blueprint.extensions,
          Extensions::Core::Postlude.new
        ])
        @formatter = Formatter.new(blueprint)
        @blueprint = blueprint
        # "Unroll" these hooks for a significant speed boost
        @defaults = Extensions::Core::Defaults.new
        @cond = Extensions::Core::Conditionals.new
        find_used_hooks!
      end

      #
      # Serialize a single object to a Hash.
      #
      # @param object [Object] The object to serialize
      # @param options [Hash] Options passed from the callsite
      # @param instances [Blueprinter::V2::InstanceCache] Singleton factory for blueprints and extensions used during this
      # serialization
      # @param store [Hash] A cache for blueprints and extensions to use during this serialization
      # @return [Hash] The serialized object
      #
      def object(object, options, instances, stores)
        fields = stores[blueprint][blueprint.object_id] ||= prepare!(options, instances, stores)
        if @run_around_object
          ctx = Context::Object.new(instances[blueprint], options, instances, stores, object)
          hooks.around(:around_object_serialization, ctx) { serialize(object, options, fields, instances, stores) }
        else
          serialize(object, options, fields, instances, stores)
        end
      end

      #
      # Serialize a collection of objects to a Hash.
      #
      # @param collection [Object] The collection to serialize
      # @param options [Hash] Options passed from the callsite
      # @param instances [Blueprinter::V2::InstanceCache] Singleton factory for blueprints and extensions used during this
      # serialization
      # @param store [Hash] A cache for blueprints and extensions to use during this serialization
      # @return [Array<Hash>] The serialized objects
      #
      def collection(collection, options, instances, stores)
        fields = stores[blueprint][blueprint.object_id] ||= prepare!(options, instances, stores)
        if @run_around_collection
          ctx = Context::Object.new(instances[blueprint], options, instances, stores, collection)
          hooks.around(:around_collection_serialization, ctx) do
            collection.map { |object| serialize(object, options, fields, instances, stores) }.to_a
          end
        else
          collection.map { |object| serialize(object, options, fields, instances, stores) }.to_a
        end
      end

      private

      # rubocop:disable Metrics/MethodLength
      def serialize(object, options, fields, instances, stores)
        if @run_blueprint_input
          ctx = Context::Object.new(instances[blueprint], options, instances, stores, object)
          object = hooks.reduce_into(:blueprint_input, ctx, :object)
        end

        ctx = Context::Field.new(instances[blueprint], options, instances, stores, object, nil, nil)
        result = fields.each_with_object({}) do |field_conf, acc|
          ctx.field = field_conf.field
          ctx.value = nil
          ctx.value = ctx.field.value_proc ? proc_value(ctx) : hooks.call(field_conf.extractor, :extract_value, ctx)
          field_conf.serialize(ctx, acc)
        end

        if @run_blueprint_output
          ctx = Context::Result.new(ctx.blueprint, options, instances, stores, object, result)
          hooks.reduce_into(:blueprint_output, ctx, :result)
        else
          result
        end
      end
      # rubocop:enable Metrics/MethodLength

      # @param ctx [Blueprinter::V2::Context::Field]
      def proc_value(ctx)
        ctx.with_store ctx.blueprint
        ctx.blueprint.instance_exec(ctx, &ctx.field.value_proc)
      end

      # Allow extensions to do time-saving prep work on the current context
      def prepare!(options, instances, stores)
        ctx = Context::Render.new(instances[blueprint], options, instances, stores)
        fields = hooks.last(:blueprint_fields, ctx).map { |field| prepare_field(field, instances, stores) }.freeze
        defaults.prepare ctx.with_store(defaults)
        cond.prepare ctx.with_store(cond)
        hooks.run(:prepare, ctx) if @run_prepare
        fields
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def prepare_field(field, instances, stores)
        extractor = instances[field.options[:extractor]] || hooks.last_with(:extract_value)
        stores[blueprint][extractor.object_id] ||= extractor.prepare(ctx) || true if extractor.respond_to?(:prepare)

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
        @run_prepare = hooks.registered? :prepare
        @run_blueprint_input = hooks.registered? :blueprint_input
        @run_blueprint_output = hooks.registered? :blueprint_output
      end
    end
  end
end
