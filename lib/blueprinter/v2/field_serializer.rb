# frozen_string_literal: true

module Blueprinter
  module V2
    class FieldSerializer
      attr_reader :field, :extractor, :hooks, :defaults, :cond, :formatter

      def initialize(field, extractor, serializer)
        @field = field
        @extractor = extractor
        @hooks = serializer.hooks
        @defaults = serializer.defaults
        @cond = serializer.cond
        @formatter = serializer.formatter
        find_used_hooks!
      end

      class Field < self
        def serialize(ctx, result)
          ctx.value = defaults.field_value ctx.with_store(defaults)
          hooks.reduce_into(:field_value, ctx, :value) if @run_field_value
          ctx.value = formatter.call(ctx)
          return if cond.exclude_field?(ctx.with_store(cond)) || (@run_ex_field && hooks.any?(:exclude_field?, ctx))

          result[ctx.field.name] = ctx.value
        end
      end

      class Object < self
        def serialize(ctx, result)
          field = ctx.field
          instances = ctx.instances
          ctx.value = defaults.object_value ctx.with_store(defaults)
          hooks.reduce_into(:object_value, ctx, :value) if @run_object_value
          return if cond.exclude_object?(ctx.with_store(cond)) || (@run_ex_object && hooks.any?(:exclude_object?, ctx))

          if ctx.value
            ctx.value =
              if instances[field.blueprint].is_a? V2::Base
                field.blueprint.serializer.object(ctx.value, ctx.options, instances, ctx.stores)
              else
                legacy_opts = { v2_instances: instances, v2_stores: ctx.stores }
                field.blueprint.render_as_hash(ctx.value, ctx.options.dup.merge(legacy_opts))
              end
          end
          result[field.name] = ctx.value
        end
      end

      class Collection < self
        # rubocop:disable Metrics/MethodLength
        def serialize(ctx, result)
          field = ctx.field
          instances = ctx.instances
          ctx.value = defaults.collection_value ctx.with_store(defaults)
          hooks.reduce_into(:collection_value, ctx, :value) if @run_collection_value
          ctx.with_store cond
          return if cond.exclude_collection?(ctx) || (@run_ex_collection && hooks.any?(:exclude_collection?, ctx))

          if ctx.value
            ctx.value =
              if instances[field.blueprint].is_a? V2::Base
                field.blueprint.serializer.collection(ctx.value, ctx.options, instances, ctx.stores)
              else
                legacy_opts = { v2_instances: instances, v2_stores: ctx.stores }
                field.blueprint.render_as_hash(ctx.value, ctx.options.dup.merge(legacy_opts))
              end
          end
          result[field.name] = ctx.value
        end
        # rubocop:enable Metrics/MethodLength
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
      end
    end
  end
end
