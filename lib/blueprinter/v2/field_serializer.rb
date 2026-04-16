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
          value = extract(config.blueprint, field, object, ctx)
          next unless config.conditionals.include?(ctx, value)

          value = config.defaults.value_or_default(ctx, value)
          result[field.name] =
            case field.type
            when :field
              if @hook_around_field_value
                @hooks.around(:around_field_value, ctx) do |ctx|
                  @formatter.call(value, ctx)
                end
              else
                @formatter.call(value, ctx)
              end
            when :object
              if @hook_around_object_value
                @hooks.around(:around_object_value, ctx) do
                  serialize_object(field, config.options, object, value, instances:, store:, depth:)
                end
              else
                serialize_object(field, config.options, object, value, instances:, store:, depth:)
              end
            when :collection
              if @hook_around_collection_value
                @hooks.around(:around_collection_value, ctx) do
                  serialize_collection(field, config.options, ctx.object, value, instances:, store:, depth:)
                end
              else
                serialize_collection(field, config.options, object, value, instances:, store:, depth:)
              end
            end
        end
        # rubocop:enable Metrics/BlockLength
      end
      # rubocop:enable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity

      private

      def extract(blueprint, field, object, ctx)
        if field.value_proc
          blueprint.instance_exec(object, ctx, &field.value_proc)
        elsif object.is_a? Hash
          object[field.from] || object[field.from_str]
        else
          object.public_send(field.from)
        end
      end

      def serialize_object(field, options, object, value, instances:, store:, depth:)
        if field.blueprint < V2::Base
          # TODO: can we re-use this object?
          parent = Context::Parent.new(@blueprint_class, field, object)
          field.blueprint.serializer.object(value, options, parent:, instances:, store:, depth: depth + 1)
        else
          opts = { v2_instances: instances, v2_depth: depth, v2_store: store }
          field.blueprint.hashify(value, view_name: :default, local_options: options.dup.merge(opts))
        end
      end

      def serialize_collection(field, options, object, value, instances:, store:, depth:)
        if field.blueprint < V2::Base
          # TODO: can we re-use this object?
          parent = Context::Parent.new(@blueprint_class, field, object)
          field.blueprint.serializer.collection(value, options, parent:, instances:, store:, depth: depth + 1)
        else
          opts = { v2_instances: instances, v2_depth: depth, v2_store: store }
          field.blueprint.hashify(value, view_name: :default, local_options: options.dup.merge(opts))
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
