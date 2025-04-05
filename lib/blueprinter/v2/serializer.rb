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
      attr_reader :blueprint, :formatter, :hooks, :values, :cond

      def initialize(blueprint)
        @hooks = Hooks.new([Extensions::Core::Prelude.new, *blueprint.extensions, Extensions::Core::Postlude.new])
        @formatter = Formatter.new(blueprint)
        @blueprint = blueprint
        # "Unroll" these hooks for a significant speed boost
        @values = Extensions::Core::Values.new
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

      # rubocop:disable Metrics/MethodLength
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
            serialize_field(ctx, acc)
          when ObjectField
            serialize_object(ctx, acc)
          when Collection
            serialize_collection(ctx, acc)
          end
        end

        if @run_blueprint_output
          ctx = Context::Result.new(ctx.blueprint, options, instances, store, object, result)
          hooks.reduce_into(:blueprint_output, ctx, :result)
        else
          result
        end
      end
      # rubocop:enable Metrics/MethodLength

      def serialize_field(ctx, result)
        ctx.value = values.field_value ctx
        hooks.reduce_into(:field_value, ctx, :value) if @run_field_value
        ctx.value = formatter.call(ctx)
        return if cond.exclude_field?(ctx) || (@run_exclude_field && hooks.any?(:exclude_field?, ctx))

        result[ctx.field.name] = ctx.value
      end

      def serialize_object(ctx, result)
        field = ctx.field
        instances = ctx.instances
        ctx.value = values.object_value ctx
        hooks.reduce_into(:object_value, ctx, :value) if @run_object_value
        return if cond.exclude_object?(ctx) || (@run_exclude_object && hooks.any?(:exclude_object?, ctx))

        if ctx.value
          ctx.value =
            if instances[field.blueprint].is_a? V2::Base
              field.blueprint.serializer.object(ctx.value, ctx.options, instances, ctx.store)
            else
              store = ctx.store
              field.blueprint.render_as_hash(ctx.value, ctx.options.dup.merge({ v2_instances: instances, v2_store: store }))
            end
        end
        result[field.name] = ctx.value
      end

      def serialize_collection(ctx, result)
        field = ctx.field
        instances = ctx.instances
        ctx.value = values.collection_value ctx
        hooks.reduce_into(:collection_value, ctx, :value) if @run_collection_value
        return if cond.exclude_collection?(ctx) || (@run_exclude_collection && hooks.any?(:exclude_collection?, ctx))

        if ctx.value
          ctx.value =
            if instances[field.blueprint].is_a? V2::Base
              field.blueprint.serializer.collection(ctx.value, ctx.options, instances, ctx.store)
            else
              store = ctx.store
              field.blueprint.render_as_hash(ctx.value, ctx.options.dup.merge({ v2_instances: instances, v2_store: store }))
            end
        end
        result[field.name] = ctx.value
      end

      # Allow extensions to do time-saving prep work on the current context
      def prepare!(options, instances, store)
        ctx = Context::Render.new(instances[blueprint], options, instances, store)
        values.prepare ctx
        cond.prepare ctx
        hooks.run(:prepare, ctx) if @run_prepare
        hooks.last(:blueprint_fields, ctx).freeze
      end

      # We save a lot of time by skipping hooks that aren't used
      def find_used_hooks!
        @run_around_object = hooks.registered? :around_object_serialization
        @run_around_collection = hooks.registered? :around_collection_serialization
        @run_prepare = hooks.registered? :prepare
        @run_blueprint_input = hooks.registered? :blueprint_input
        @run_blueprint_output = hooks.registered? :blueprint_output
        @run_field_value = hooks.registered? :field_value
        @run_object_value = hooks.registered? :object_value
        @run_collection_value = hooks.registered? :collection_value
        @run_exclude_field = hooks.registered? :exclude_field?
        @run_exclude_object = hooks.registered? :exclude_object?
        @run_exclude_collection = hooks.registered? :exclude_collection?
      end
    end
  end
end
