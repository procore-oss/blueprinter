# frozen_string_literal: true

require 'blueprinter/hooks'
require 'blueprinter/v2/conditionals'
require 'blueprinter/v2/defaults'
require 'blueprinter/v2/formatter'

module Blueprinter
  module V2
    #
    # The serializer for a given Blueprint. Takes in an object with options and serializes it to a Hash.
    #
    # NOTE: The instance is re-used for the duration of the render.
    #
    class Serializer2
      Config = Struct.new(:blueprint, :fields, :options, :conditionals, :defaults, keyword_init: true)
      attr_reader :blueprint_class, :hooks

      def initialize(blueprint_class)
        @blueprint_class = blueprint_class
        @formatter = Formatter.new(blueprint_class)
        @hooks = Hooks.new(extensions)
        find_used_hooks!
      end

      def object(object, options, instances:, store:, depth:, parent: nil)
        config = store[@blueprint_class.object_id] ||= blueprint_init(options, instances:, store:, depth:)
        if @hook_around_serialize_object
          # TODO: creating these context objects is a lot of overhead - can we re-use objects?
          ctx = Context::Object.new(config.blueprint, config.fields, config.options, object, parent, store, depth)
          @hooks.around(:around_serialize_object, ctx) do |ctx|
            serialize(config, ctx.object, parent:, instances:, store:, depth:)
          end
        else
          serialize(config, object, parent:, instances:, store:, depth:)
        end
      end

      def collection(objects, options, instances:, store:, depth:, parent: nil)
        config = store[@blueprint_class.object_id] ||= blueprint_init(options, instances:, store:, depth:)
        if @hook_around_serialize_collection
          # TODO: creating these context objects is a lot of overhead - can we re-use objects?
          ctx = Context::Object.new(config.blueprint, config.fields, config.options, objects, parent, store, depth)
          @hooks.around(:around_serialize_collection, ctx) do |ctx|
            ctx.object.map { |object| serialize(config, object, parent:, instances:, store:, depth:) }
          end
        else
          objects.map { |object| serialize(config, object, parent:, instances:, store:, depth:) }
        end
      end

      def fields
        @fields ||= blueprint_class.reflections[:default].ordered
      end

      private

      def serialize(config, object, parent:, instances:, store:, depth:)
        if @hook_around_blueprint
          # TODO: creating these context objects is a lot of overhead - can we re-use objects?
          ctx = Context::Object.new(config.blueprint, config.fields, config.options, object, parent, store, depth)
          @hooks.around(:around_blueprint, ctx) do |ctx|
            _serialize(config, object, instances:, store:, depth:)
          end
        else
          _serialize(config, object, instances:, store:, depth:)
        end
      end

      def _serialize(config, object, instances:, store:, depth:)
        ctx = Context::Field.new(config.blueprint, config.fields, config.options, object, nil, store, depth)
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
                  serialize_collection(field, config.options, object, value, instances:, store:, depth:)
                end
              else
                serialize_collection(field, config.options, object, value, instances:, store:, depth:)
              end
            end
        end
      end

      def serialize_object(field, options, object, value, instances:, store:, depth:)
        if field.blueprint < V2::Base
          parent = Context::Parent.new(@blueprint_class, field, object)
          field.blueprint.serializer.object(value, options, parent:, instances:, store:, depth: depth + 1)
        else
          opts = { v2_instances: @instances, v2_depth: depth, v2_store: store }
          field.blueprint.hashify(value, view_name: :default, local_options: options.dup.merge(opts))
        end
      end

      def serialize_collection(field, options, object, value, instances:, store:, depth:)
        if field.blueprint < V2::Base
          parent = Context::Parent.new(@blueprint_class, field, object)
          field.blueprint.serializer.collection(value, options, parent:, instances:, store:, depth: depth + 1)
        else
          opts = { v2_instances: @instances, v2_depth: depth, v2_store: store }
          field.blueprint.hashify(value, view_name: :default, local_options: options.dup.merge(opts))
        end
      end

      def extract(blueprint, field, object, ctx)
        if field.value_proc
          blueprint.instance_exec(object, ctx, &field.value_proc)
        elsif object.is_a? Hash
          object[field.from] || object[field.from_str]
        else
          object.public_send(field.from)
        end
      end

      def blueprint_init(options, instances:, store:, depth:)
        blueprint = instances.blueprint(blueprint_class)
        conditionals = Conditionals.new(blueprint, options)
        defaults = Defaults.new(blueprint, options)
        config = Config.new(blueprint:, fields:, options:, conditionals:, defaults:)

        ctx = Context::Render.new(blueprint, fields, options, store, depth)
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

      # We save a lot of time by skipping hooks that aren't used
      def find_used_hooks!
        @hook_around_serialize_object = @hooks.registered? :around_serialize_object
        @hook_around_serialize_collection = @hooks.registered? :around_serialize_collection
        @hook_around_blueprint = @hooks.registered? :around_blueprint
        @hook_around_field_value = @hooks.registered? :around_field_value
        @hook_around_object_value = @hooks.registered? :around_object_value
        @hook_around_collection_value = @hooks.registered? :around_collection_value
      end
    end
  end
end
