# frozen_string_literal: true

require 'blueprinter/v2/formatter'
require 'blueprinter/hooks'

module Blueprinter
  module V2
    # @api private
    class Serializer
      SIGNAL = :_blueprinter_signal
      SIG_SKIP = :_blueprinter_signal_skip
      Config = Struct.new(:blueprint, :fields, :options, keyword_init: true)

      attr_reader :hooks, :formatter

      def initialize(blueprint_class)
        @blueprint_class = blueprint_class
        @formatter = Formatter.new(blueprint_class)
        @format = @formatter.any?
        @hooks = Hooks.new([*blueprint_class.extensions, Extensions::Core::Json.new, Extensions::Core::Wrapper.new])
        finalize_fields!
        find_used_hooks!
        @needs_field_ctx = needs_field_ctx?
      end

      def object(object, options, instances:, store:, depth: 1, parent: nil)
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

      def collection(objects, options, instances:, store:, depth: 1, parent: nil)
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
        ctx = @needs_field_ctx ? Context::Field.new(blueprint, fields, options, nil, nil, store, depth) : nil
        parent = nil
        # rubocop:disable Metrics/BlockLength
        objects.map do |object|
          ctx&.object = object
          fields.each_with_object({}) do |field, result|
            ctx&.field = field
            next if field._has_conditional && FieldLogic.skip?(ctx, field)

            # extract value
            if (field_hook = @field_hooks[field.type])
              value = catch SIGNAL do
                @hooks.around(field_hook, ctx) do
                  val = field._extractor.extract(field, object, ctx:)
                  field._has_default ? FieldLogic.value_or_default(ctx, field, val) : val
                end
              end
              next if value == SIG_SKIP
            else
              value = field._extractor.extract(field, object, ctx:)
              value = FieldLogic.value_or_default(ctx, field, value) if field._has_default
            end

            # format/serialize and set value
            result[field.name] =
              if value.nil?
                field._merged_options[:exclude_if_nil] ? next : nil
              elsif field.type == :field
                @format ? @formatter.call(blueprint, value) : value
              else
                parent ||= Context::Parent.new(@blueprint_class)
                parent.field = field
                parent.object = object
                field._serializer.serialize(field.blueprint, value, options, parent:, instances:, store:, depth: depth + 1)
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
          ctx = Context::Init.new(blueprint, config.fields.dup, options, store, depth)
          @hooks.around(:around_blueprint_init, ctx, require_yield: true) do |ctx|
            config.fields = ctx.fields.dup.freeze unless ctx.fields == config.fields
          end
        end
        config.freeze
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

      # Skip Context::Field allocation when no field hooks, conditionals, callable defaults, or Proc extractors are in play
      def needs_field_ctx?
        @field_hooks.values.any? || default_fields.any? do |f|
          default = f._merged_options[:default]
          callable_default = default.is_a?(Proc) || default.is_a?(Symbol)
          f._has_conditional || !!f.value_proc || !!f._merged_options[:default_if] || callable_default
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def finalize_fields!
        options = @blueprint_class.options
        @blueprint_class.schema.each_value do |field|
          # copy blueprint options down to each field (faster b/c we can check exactly one Hash)
          field._merged_options = field.options.dup
          field._merged_options[:if] ||= options[:if] if options.key? :if
          field._merged_options[:unless] ||= options[:unless] if options.key? :unless
          field._merged_options[:default_if] ||= options[:default_if] if options.key? :default_if
          field._merged_options[:default] = options[:default] if options.key?(:default) && !field.options.key?(:default)
          field._merged_options[:exclude_if_nil] = options[:exclude_if_nil] if options.key?(:exclude_if_nil) &&
                                                                               !field.options.key?(:exclude_if_nil)
          field._merged_options.freeze

          # precompute some checks
          field._extractor = field.value_proc ? Extractors::Proc : Extractors::Property
          field._has_conditional = field._merged_options.key?(:if) || field._merged_options.key?(:unless)
          field._has_default = field._merged_options.key?(:default) || field._merged_options.key?(:default_if)
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    end
  end
end
