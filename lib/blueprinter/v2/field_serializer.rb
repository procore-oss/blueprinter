# frozen_string_literal: true

require 'blueprinter/v2/formatter'

module Blueprinter
  module V2
    class FieldSerializer
      def initialize(blueprint_class, hooks)
        @blueprint_class = blueprint_class
        @hooks = hooks
        @formatter = Formatter.new(blueprint_class)
        @field_hooks = used_field_hooks
      end

      # NOTE: This method is long, ugly, and non-compliant b/c it's in the hot path
      # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      def serialize(config, object, instances:, store:, depth:)
        parent = Context::Parent.new(@blueprint_class)
        ctx = Context::Field.new(config.blueprint, config.fields, config.options, object, nil, store, depth)
        # rubocop:disable Metrics/BlockLength
        config.fields.each_with_object({}) do |field, result|
          ctx.field = field
          value =
            if (field_hook = @field_hooks[field.type])
              value = catch Serializer::SIGNAL do
                @hooks.around(field_hook, ctx) do
                  value = extract(config, field, object, ctx)
                  config.conditionals.include?(ctx, value) ? value : throw(Serializer::SIGNAL, Serializer::SIG_SKIP)
                end
              end
              value == Serializer::SIG_SKIP ? next : value
            else
              value = extract(config, field, object, ctx)
              config.conditionals.include?(ctx, value) ? value : next
            end

          result[field.name] =
            case field.type
            when :field
              @formatter.call(value, ctx)
            when :object
              if value
                if field.blueprint < V2::Base
                  parent.field = field
                  parent.object = object
                  field.blueprint.serializer.object(value, config.options, parent:, instances:, store:, depth: depth + 1)
                else
                  opts = { v2_instances: instances, v2_depth: depth, v2_store: store }
                  field.blueprint.hashify(value, view_name: :default, local_options: config.options.dup.merge(opts))
                end
              end
            when :collection
              if value
                if field.blueprint < V2::Base
                  parent.field = field
                  parent.object = object
                  field.blueprint.serializer.collection(value, config.options, parent:, instances:, store:, depth: depth + 1)
                else
                  opts = { v2_instances: instances, v2_depth: depth, v2_store: store }
                  field.blueprint.hashify(value, view_name: :default, local_options: config.options.dup.merge(opts))
                end
              end
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
        config.defaults.value_or_default(ctx, value)
      end

      # We save a lot of time by skipping hooks that aren't used
      def used_field_hooks
        {
          field: @hooks.registered?(:around_field_value) ? :around_field_value : nil,
          object: @hooks.registered?(:around_object_value) ? :around_object_value : nil,
          collection: @hooks.registered?(:around_collection_value) ? :around_collection_value : nil
        }.freeze
      end
    end
  end
end
