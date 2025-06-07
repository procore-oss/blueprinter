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

      class Field < self
        def serialize(ctx, result)
          ctx.value = defaults.field_value ctx
          hooks.reduce_into(:field_value, ctx, :value) if @run_field_value
          ctx.value = formatter.call(ctx)
          return if cond.exclude_field?(ctx) || (@run_ex_field && hooks.any?(:exclude_field?, ctx))

          result[ctx.field.name] = ctx.value
        end
      end

      class Object < self
        def serialize(ctx, result)
          ctx.value = defaults.object_value ctx
          hooks.reduce_into(:object_value, ctx, :value) if @run_object_value
          return if cond.exclude_object?(ctx) || (@run_ex_object && hooks.any?(:exclude_object?, ctx))

          result[ctx.field.name] = ctx.value.nil? ? nil : blueprint_value(ctx)
        end

        private

        def blueprint_value(ctx)
          blueprint = ctx.field.blueprint
          if instances.blueprint(blueprint).is_a? V2::Base
            child_serializer = instances.serializer(blueprint, ctx.options)
            value = child_serializer.object(ctx.value)
            return value unless @run_object_output

            result_ctx = Context::Field.new(ctx.blueprint, ctx.options, ctx.object, ctx.field, value)
            hooks.reduce_into(:object_output, result_ctx, :value)
          else
            opts = { v2_instances: instances }
            blueprint.hashify(ctx.value, view_name: :default, local_options: ctx.options.dup.merge(opts))
          end
        end
      end

      class Collection < self
        def serialize(ctx, result)
          ctx.value = defaults.collection_value ctx
          hooks.reduce_into(:collection_value, ctx, :value) if @run_collection_value
          return if cond.exclude_collection?(ctx) || (@run_ex_collection && hooks.any?(:exclude_collection?, ctx))

          result[ctx.field.name] = ctx.value.nil? ? nil : blueprint_value(ctx)
        end

        private

        def blueprint_value(ctx)
          blueprint = ctx.field.blueprint
          if instances.blueprint(blueprint).is_a? V2::Base
            child_serializer = instances.serializer(blueprint, ctx.options)
            value = child_serializer.collection(ctx.value)
            return value unless @run_collection_output

            result_ctx = Context::Field.new(ctx.blueprint, ctx.options, ctx.object, ctx.field, value)
            hooks.reduce_into(:collection_output, result_ctx, :value)
          else
            opts = { v2_instances: instances }
            blueprint.hashify(ctx.value, view_name: :default, local_options: ctx.options.dup.merge(opts))
          end
        end
      end

      private

      # We save a lot of time by skipping hooks that aren't used
      def find_used_hooks!
        @run_field_value = hooks.registered? :field_value
        @run_object_value = hooks.registered? :object_value
        @run_collection_value = hooks.registered? :collection_value
        @run_ex_field = hooks.registered? :exclude_field?
        @run_ex_object = hooks.registered? :exclude_object?
        @run_ex_collection = hooks.registered? :exclude_collection?
        @run_object_output = hooks.registered? :object_output
        @run_collection_output = hooks.registered? :collection_output
      end
    end
  end
end
