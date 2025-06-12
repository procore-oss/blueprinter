# frozen_string_literal: true

module Blueprinter
  module V2
    class FieldSerializer
      attr_reader :field, :extractor, :instances, :hooks, :defaults, :cond, :formatter

      def initialize(field, extractor, serializer)
        @field = field
        @extractor = extractor
        @instances = serializer.instances
        @hooks = serializer.hooks
        @defaults = serializer.defaults
        @cond = serializer.cond
        @formatter = serializer.formatter
        find_used_hooks!
      end

      # Serializesr for regular fields
      class Field < self
        def serialize(ctx, result)
          ctx.value = defaults.field_value ctx
          hooks.reduce_into(:field_value, ctx, :value) if @run_field_value
          ctx.value = formatter.call(ctx)
          return if cond.exclude_field?(ctx) || (@run_ex_field && hooks.any?(:exclude_field?, ctx))

          hooks.reduce_into(:field_result, ctx, :value) if @run_field_result
          result[ctx.field.name] = ctx.value
        end
      end

      # Serializesr for object fields
      class Object < self
        def serialize(ctx, result)
          ctx.value = defaults.object_field_value ctx
          hooks.reduce_into(:object_field_value, ctx, :value) if @run_object_field_value
          return if cond.exclude_object_field?(ctx) || (@run_ex_object && hooks.any?(:exclude_object_field?, ctx))

          hooks.reduce_into(:object_field_result, ctx, :value) if @run_object_field_result
          result[ctx.field.name] = ctx.value.nil? ? nil : blueprint_value(ctx)
        end

        private

        def blueprint_value(ctx)
          field_blueprint = ctx.field.blueprint
          if instances.blueprint(field_blueprint).is_a? V2::Base
            child_serializer = instances.serializer(field_blueprint, ctx.options, ctx.depth + 1)
            child_serializer.object(ctx.value, depth: ctx.depth + 1)
          else
            opts = { v2_instances: instances, v2_depth: ctx.depth }
            field_blueprint.hashify(ctx.value, view_name: :default, local_options: ctx.options.dup.merge(opts))
          end
        end
      end

      # Serializesr for collection fields
      class Collection < self
        def serialize(ctx, result)
          ctx.value = defaults.collection_field_value ctx
          hooks.reduce_into(:collection_field_value, ctx, :value) if @run_collection_field_value
          return if cond.exclude_collection_field?(ctx) ||
                    (@run_ex_collection && hooks.any?(:exclude_collection_field?, ctx))

          hooks.reduce_into(:collection_field_result, ctx, :value) if @run_collection_field_result
          result[ctx.field.name] = ctx.value.nil? ? nil : blueprint_value(ctx)
        end

        private

        def blueprint_value(ctx)
          field_blueprint = ctx.field.blueprint
          if instances.blueprint(field_blueprint).is_a? V2::Base
            child_serializer = instances.serializer(field_blueprint, ctx.options, ctx.depth + 1)
            child_serializer.collection(ctx.value, depth: ctx.depth + 1)
          else
            opts = { v2_instances: instances, v2_depth: ctx.depth }
            field_blueprint.hashify(ctx.value, view_name: :default, local_options: ctx.options.dup.merge(opts))
          end
        end
      end

      private

      # We save a lot of time by skipping hooks that aren't used
      def find_used_hooks!
        @run_field_value = hooks.registered? :field_value
        @run_object_field_value = hooks.registered? :object_field_value
        @run_collection_field_value = hooks.registered? :collection_field_value
        @run_ex_field = hooks.registered? :exclude_field?
        @run_ex_object = hooks.registered? :exclude_object_field?
        @run_ex_collection = hooks.registered? :exclude_collection_field?
        @run_field_result = hooks.registered? :field_result
        @run_object_field_result = hooks.registered? :object_field_result
        @run_collection_field_result = hooks.registered? :collection_field_result
      end
    end
  end
end
