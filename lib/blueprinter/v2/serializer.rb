# frozen_string_literal: true

require 'blueprinter/v2/formatter'
require 'blueprinter/hooks'

module Blueprinter
  module V2
    # @api private
    # rubocop:disable Metrics/ClassLength
    class Serializer
      SIGNAL = :_blueprinter_signal
      SIG_SKIP = :_blueprinter_signal_skip
      Config = Struct.new(:blueprint, :fields, :options, keyword_init: true)

      attr_reader :hooks, :formatter

      def initialize(blueprint_class)
        @blueprint_class = blueprint_class
        @formatter = Formatter.new(blueprint_class)
        @format = @formatter.any?
        @hooks = Hooks.new(extensions)
        find_used_hooks!
        finalize_fields!
      end

      def object(object, options, instances:, store:, depth:, parent: nil)
        blueprint = instances.blueprint(@blueprint_class)
        config = store[blueprint.object_id] ||= blueprint_init(blueprint, options, store:, depth:)

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
        config = store[blueprint.object_id] ||= blueprint_init(blueprint, options, store:, depth:)

        if @hook_around_serialize_collection
          ctx = Context::Object.new(blueprint, config.fields, config.options, objects, parent, store, depth)
          @hooks.around(:around_serialize_collection, ctx) do |ctx|
            serialize(blueprint, config.fields, config.options, ctx.object, instances:, store:, depth:).to_a
          end
        else
          serialize(blueprint, config.fields, config.options, objects, instances:, store:, depth:).to_a
        end
      end

      def default_fields
        @_default_fields ||= @blueprint_class.schema.values.freeze
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
            next if field.has_conditional && FieldLogic.skip?(ctx, field)

            # extract value
            value =
              if (field_hook = @field_hooks[field.type])
                value = catch SIGNAL do
                  @hooks.around(field_hook, ctx) do
                    value = field.extractor.extract(ctx)
                    field.has_default ? FieldLogic.value_or_default(ctx, field, value) : value
                  end
                end
                value == SIG_SKIP ? next : value
              else
                value = field.extractor.extract(ctx)
                field.has_default ? FieldLogic.value_or_default(ctx, field, value) : value
              end

            # format/serialize and set value
            result[field.name] =
              if value.nil?
                field.options[:exclude_if_nil] ? next : nil
              elsif field.type == :field
                @format ? @formatter.call(ctx, value) : value
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

      # Runs any around_blueprint_init hooks on this Blueprint and returns the configuration that should be used.
      # Only runs the FIRST time a given Blueprint is used during a given render.
      #
      # @param blueprint [Blueprinter::V2::Base] The Blueprint instance
      # @param options [Hash] Options given to `render`
      # @param store [Hash] The context store for this render
      # @param depth [Integer] Current serialization depth
      # @return [Blueprinter::V2::Serializer::Config]
      def blueprint_init(blueprint, options, store:, depth:)
        config = Config.new(blueprint:, fields: default_fields, options:)
        if @hook_around_blueprint_init
          ctx = Context::Render.new(blueprint, config.fields, options, store, depth)
          @hooks.around(:around_blueprint_init, ctx, require_yield: true) do |ctx|
            config.options = ctx.options.dup.freeze unless ctx.options == config.options
            config.fields = ctx.fields.freeze
          end
        end
        config.freeze
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
        @hook_around_blueprint_init = @hooks.registered? :around_blueprint_init
        @field_hooks = {
          field: @hooks.registered?(:around_field_value) ? :around_field_value : nil,
          object: @hooks.registered?(:around_object_value) ? :around_object_value : nil,
          collection: @hooks.registered?(:around_collection_value) ? :around_collection_value : nil
        }.freeze
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def finalize_fields!
        options = @blueprint_class.options
        @blueprint_class.schema.each_value do |field|
          # precompute some checks
          field.extractor = field.value_proc ? Extractors::Proc : Extractors::Property
          field.has_conditional = field.options.key?(:if) || field.options.key?(:unless)
          field.has_default = field.options.key?(:default) || field.options.key?(:default_if)
          # copy blueprint options down to each field (so the serializer has a single place to check)
          field.original_options = field.options.dup
          field.options[:if] ||= options[:if] if options.key? :if
          field.options[:unless] ||= options[:unless] if options.key? :unless
          field.options[:default_if] ||= options[:default_if] if options.key? :default_if
          field.options[:default] = options[:default] if options.key?(:default) && !field.options.key?(:default)
          field.options[:exclude_if_nil] = options[:exclude_if_nil] if options.key?(:exclude_if_nil) &&
                                                                       !field.options.key?(:exclude_if_nil)
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    end
    # rubocop:enable Metrics/ClassLength
  end
end
