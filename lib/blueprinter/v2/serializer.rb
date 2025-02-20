# frozen_string_literal: true

require 'blueprinter/hooks'
require 'blueprinter/v2/formatter'

module Blueprinter
  module V2
    #
    # The serializer for a given Blueprint. Takes in an object with options and serializes it to a Hash.
    #
    # NOTE: Each Blueprint gets a *single* Serializer instance that will live for the duration of the application.
    #
    class Serializer
      attr_reader :blueprint, :formatter, :hooks

      def initialize(blueprint)
        @hooks = Hooks.new([
          Extensions::Core::Prelude.new,
          Extensions::Core::Values.new,
          *blueprint.extensions
        ])
        @formatter = Formatter.new(blueprint)
        @blueprint = blueprint
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
      def object(object, options, instances, store)
        store[blueprint.object_id] ||= prepare!(options, instances, store)
        if @run_around_object
          ctx = Context::Object.new(instances[blueprint], options, instances, store, object)
          hooks.around(:around_object_serialization, ctx) { serialize(object, options, instances, store) }
        else
          serialize(object, options, instances, store)
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
      def collection(collection, options, instances, store)
        store[blueprint.object_id] ||= prepare!(options, instances, store)
        if @run_around_collection
          ctx = Context::Object.new(instances[blueprint], options, instances, store, collection)
          hooks.around(:around_collection_serialization, ctx) do
            collection.map { |object| serialize(object, options, instances, store) }.to_a
          end
        else
          collection.map { |object| serialize(object, options, instances, store) }.to_a
        end
      end

      private

      # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      def serialize(object, options, instances, store)
        if @run_blueprint_input
          ctx = Context::Object.new(instances[blueprint], options, instances, store, object)
          object = hooks.reduce_into(:blueprint_input, ctx, :object)
        end
        ctx = Context::Field.new(instances[blueprint], options, instances, store, object, nil, nil)

        result = ctx.store.fetch(blueprint.object_id).each_with_object({}) do |field, acc|
          ctx.field = field
          ctx.value = nil

          case field
          when Field
            hooks.reduce_into(:field_value, ctx, :value)
            ctx.value = formatter.call(ctx)
            next if hooks.any?(:exclude_field?, ctx)

            acc[field.name] = ctx.value
          when ObjectField
            hooks.reduce_into(:object_value, ctx, :value)
            next if hooks.any?(:exclude_object?, ctx)

            ctx.value = field.blueprint.serializer.object(ctx.value, options, instances, store) if ctx.value
            acc[field.name] = ctx.value
          when Collection
            hooks.reduce_into(:collection_value, ctx, :value)
            next if hooks.any?(:exclude_collection?, ctx)

            ctx.value = field.blueprint.serializer.collection(ctx.value, options, instances, store) if ctx.value
            acc[field.name] = ctx.value
          end
        end

        if @run_blueprint_output
          ctx = Context::Result.new(ctx.blueprint, options, instances, store, object, result)
          hooks.reduce_into(:blueprint_output, ctx, :result)
        else
          result
        end
      end
      # rubocop:enable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

      # Allow extensions to do time-saving prep work on the current context
      def prepare!(options, instances, store)
        ctx = Context::Render.new(instances[blueprint], options, instances, store)
        hooks.run(:prepare, ctx)
        hooks.last(:blueprint_fields, ctx).freeze
      end

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
