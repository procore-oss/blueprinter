# frozen_string_literal: true

require 'blueprinter/v2/formatter'
require 'blueprinter/hooks'

module Blueprinter
  module V2
    class Serializer3
      Config = Struct.new(:blueprint, :fields, :options, keyword_init: true)

      attr_reader :hooks, :formatter

      def initialize(blueprint_class)
        @blueprint_class = blueprint_class
        @formatter = Formatter.new(blueprint_class)
        @format = @formatter.any?
        @hooks = Hooks.new(extensions)
        find_used_hooks!
      end

      def object(object, options, instances:, store:, depth:, parent: nil)
        blueprint = instances.blueprint(@blueprint_class)
        config = store[blueprint.object_id] ||= blueprint_init(options, instances:, store:, depth:)

        if @hook_around_serialize_object
          ctx = Context::Object.new(blueprint, config.fields, config.options, object, parent, store, depth)
          @hooks.around(:around_serialize_object, ctx) do |ctx|
            serialize(blueprint, config.fields, config.options, [ctx.object], instances:, store:, depth:)[0]
          end
        else
          serialize(blueprint, config.fields, config.options, [object], instances:, store:, depth:)[0]
        end
      end

      def collection(objects, options, instances:, store:, depth:, parent: nil)
        blueprint = instances.blueprint(@blueprint_class)
        config = store[blueprint.object_id] ||= blueprint_init(options, instances:, store:, depth:)

        if @hook_around_serialize_collection
          ctx = Context::Object.new(blueprint, config.fields, config.options, objects, parent, store, depth)
          @hooks.around(:around_serialize_collection, ctx) do |ctx|
            serialize(blueprint, config.fields, config.options, ctx.object, instances:, store:, depth:)[0]
          end
        else
          serialize(blueprint, config.fields, config.options, objects, instances:, store:, depth:)
        end
      end

      def default_fields
        @_default_fields ||= @blueprint_class.reflections[:default].ordered
      end

      private

      # Long and ugly for performance
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def serialize(blueprint, fields, options, objects, instances:, store:, depth:)
        ctx = Context::Field.new(blueprint, fields, options, nil, nil, store, depth)
        parent = Context::Parent.new(@blueprint_class)
        # rubocop:disable Metrics/BlockLength
        objects.map do |object|
          ctx.object = object
          fields.each_with_object({}) do |field, result|
            ctx.field = field
            # TODO: slow point
            next if FieldLogic.skip?(ctx, blueprint, field)

            # extract value
            value =
              if (field_hook = @field_hooks[field.type])
                value = catch Serializer::SIGNAL do
                  @hooks.around(field_hook, ctx) do
                    value = field.extractor.extract(ctx, blueprint, field, object)
                    FieldLogic.value_or_default(ctx, value)
                  end
                end
                value == Serializer::SIG_SKIP ? next : value
              else
                value = field.extractor.extract(ctx, blueprint, field, object)
                # TODO: slow point
                FieldLogic.value_or_default(ctx, blueprint, field, value)
              end
            next if value.nil? && ctx.field.options[:exclude_if_nil]

            # format/serialize and set value
            result[field.name] =
              if field.type == :field
                @format ? @formatter.call(value, ctx) : value
              else
                parent.field = field
                parent.object = object
                field.serializer.serialize(field.blueprint, value, options, parent:, instances:, store:, depth:)
              end
          end
          # rubocop:enable Metrics/BlockLength
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

      def blueprint_init(options, instances:, store:, depth:)
        blueprint = instances.blueprint(@blueprint_class)
        config = Config.new(blueprint:, fields: default_fields, options:)
        ctx = Context::Render.new(blueprint, default_fields, options, store, depth)
        @hooks.around(:around_blueprint_init, ctx, require_yield: true) do |ctx|
          config.options = ctx.options.freeze
          config.fields = ctx.fields.freeze
        end
        config
      end

      def extensions
        extensions = @blueprint_class.extensions.map do |ext|
          case ext
          when Extension then ext
          when Class then ext.new
          when Proc then ext.call
          else raise BlueprinterError, 'Extensions must be an instance of Blueprinter::Extension or a Proc that returns one'
          end
        end
        [*extensions, Extensions::Core::Json.new, Extensions::Core::Wrapper.new]
      end

      # Save time by skipping hooks that aren't used
      def find_used_hooks!
        @hook_around_serialize_object = @hooks.registered? :around_serialize_object
        @hook_around_serialize_collection = @hooks.registered? :around_serialize_collection
        @field_hooks = {
          field: @hooks.registered?(:around_field_value) ? :around_field_value : nil,
          object: @hooks.registered?(:around_object_value) ? :around_object_value : nil,
          collection: @hooks.registered?(:around_collection_value) ? :around_collection_value : nil
        }.freeze
      end
    end
  end
end
