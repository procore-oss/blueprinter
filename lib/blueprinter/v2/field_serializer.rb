# frozen_string_literal: true

require 'blueprinter/v2/formatter'

module Blueprinter
  module V2
    class FieldSerializer
      def initialize(blueprint_class, hooks)
        @hooks = hooks
        @formatter = Formatter.new(blueprint_class)
        find_used_hooks!
      end

      # NOTE: This method is ugly and non-compliant b/c it's in the hot path
      # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      def serialize(config, object, instances:, store:, depth:)
        ctx = Context::Field.new(config.blueprint, config.fields, config.options, object, nil, store, depth)
        # rubocop:disable Metrics/BlockLength
        config.fields.each_with_object({}) do |field, result|
          ctx.field = field
          result[field.name] =
            case field.type
            when :field
              value =
                if @hook_around_field_value
                  catch Serializer::SIGNAL do
                    @hooks.around(:around_field_value, ctx) do
                      extract(config, field, object, ctx)
                    end
                  end
                else
                  extract(config, field, object, ctx)
                end
              next if value == Serializer::SIG_SKIP

              @formatter.call(value, ctx)
            when :object
              value =
                if @hook_around_object_value
                  catch Serializer::SIGNAL do
                    @hooks.around(:around_object_value, ctx) do
                      extract(config, field, object, ctx)
                    end
                  end
                else
                  extract(config, field, object, ctx)
                end
              next if value == Serializer::SIG_SKIP

              value ? serialize_object(config, field, object, value, instances:, store:, depth:) : nil
            when :collection
              value =
                if @hook_around_collection_value
                  catch Serializer::SIGNAL do
                    @hooks.around(:around_collection_value, ctx) do
                      extract(config, field, object, ctx)
                    end
                  end
                else
                  extract(config, field, object, ctx)
                end
              next if value == Serializer::SIG_SKIP

              value ? serialize_collection(config, field, object, value, instances:, store:, depth:) : nil
            end
        end
        # rubocop:enable Metrics/BlockLength
      end
      # rubocop:enable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity

      private

      def extract(config, field, object, ctx)
        value =
          if field.value_proc
            config.blueprint.instance_exec(object, ctx, &field.value_proc)
          elsif object.is_a? Hash
            object[field.from] || object[field.from_str]
          else
            object.public_send(field.from)
          end
        return Serializer::SIG_SKIP unless config.conditionals.include?(ctx, value)

        config.defaults.value_or_default(ctx, value)
      end

      def serialize_object(config, field, object, value, instances:, store:, depth:)
        if field.blueprint < V2::Base
          config.parent_ctx.field = field
          config.parent_ctx.object = object
          field.blueprint.serializer
               .object(value, config.options, parent: config.parent_ctx, instances:, store:, depth: depth + 1)
        else
          opts = { v2_instances: instances, v2_depth: depth, v2_store: store }
          field.blueprint.hashify(value, view_name: :default, local_options: config.options.dup.merge(opts))
        end
      end

      def serialize_collection(config, field, object, value, instances:, store:, depth:)
        if field.blueprint < V2::Base
          config.parent_ctx.field = field
          config.parent_ctx.object = object
          field.blueprint.serializer
               .collection(value, config.options, parent: config.parent_ctx, instances:, store:, depth: depth + 1)
        else
          opts = { v2_instances: instances, v2_depth: depth, v2_store: store }
          field.blueprint.hashify(value, view_name: :default, local_options: config.options.dup.merge(opts))
        end
      end

      # We save a lot of time by skipping hooks that aren't used
      def find_used_hooks!
        @hook_around_field_value = @hooks.registered? :around_field_value
        @hook_around_object_value = @hooks.registered? :around_object_value
        @hook_around_collection_value = @hooks.registered? :around_collection_value
      end
    end
  end
end
