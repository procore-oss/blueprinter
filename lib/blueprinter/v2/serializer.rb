# frozen_string_literal: true

require 'blueprinter/v2/formatter'
require 'blueprinter/hooks'

module Blueprinter
  module V2
    # rubocop:disable Metrics/ClassLength
    # @api private
    class Serializer
      SIGNAL = :_blueprinter_signal
      SIG_SKIP = :_blueprinter_signal_skip
      Config = Struct.new(:blueprint, :fields, :options, :needs_field_ctx, keyword_init: true)

      attr_reader :hooks, :formatter

      def initialize(blueprint_class)
        @blueprint_class = blueprint_class
        @formatter = Formatter.new(blueprint_class)
        @format = @formatter.any?
        @hooks = Hooks.new([Extensions::Core::Format.new, *blueprint_class.extensions, Extensions::Core::Root.new])
        finalize_fields! @blueprint_class.schema.each_value.freeze, blueprint_class.options
        find_used_hooks!
        @needs_field_ctx = needs_field_ctx? default_fields
      end

      def object(object, options, instances:, store:, depth: 1, parent: nil)
        config = store[@blueprint_class.object_id] ||= blueprint_init(instances, options, store:, depth:)
        field_ctx = config.needs_field_ctx ? build_field_ctx(config, store:, depth:) : nil
        blueprint_ctx = @hook_around_blueprint ? build_object_ctx(config, parent:, store:, depth:) : nil

        if @hook_around_serialize_object
          ctx = build_object_ctx(config, object:, parent:, store:, depth:)
          @hooks.around(:around_serialize_object, ctx) do |ctx|
            config.options = ctx.options.freeze
            blueprint_ctx&.options = config.options
            serialize(config, ctx.object, instances:, store:, depth:, field_ctx:, ctx: blueprint_ctx)
          end
        else
          serialize(config, object, instances:, store:, depth:, field_ctx:, ctx: blueprint_ctx)
        end
      end

      def collection(objects, options, instances:, store:, depth: 1, parent: nil)
        config = store[@blueprint_class.object_id] ||= blueprint_init(instances, options, store:, depth:)
        if @hook_around_serialize_collection
          ctx = build_object_ctx(config, object: objects, parent:, store:, depth:)
          @hooks.around(:around_serialize_collection, ctx) do |ctx|
            config.options = ctx.options.freeze
            serialize_collection(config, ctx.object, parent:, instances:, store:, depth:)
          end
        else
          serialize_collection(config, objects, parent:, instances:, store:, depth:)
        end
      end

      def default_fields
        @_default_fields ||= @blueprint_class.schema.values.freeze
      end

      private

      def serialize_collection(config, objects, parent:, instances:, store:, depth:)
        ctx = @hook_around_blueprint ? build_object_ctx(config, parent:, store:, depth:) : nil
        field_ctx = config.needs_field_ctx ? build_field_ctx(config, store:, depth:) : nil

        objects.map do |object|
          serialize(config, object, instances:, store:, depth:, field_ctx:, ctx:)
        end.to_a
      end

      def build_field_ctx(config, store:, depth:)
        Context::Field.new(config.blueprint, config.fields, config.options, nil, nil, store, depth)
      end

      def build_object_ctx(config, store:, depth:, object: nil, parent: nil)
        Context::Object.new(config.blueprint, config.fields, config.options, object, parent, store, depth)
      end

      def serialize(config, object, instances:, store:, depth:, ctx: nil, field_ctx: nil)
        if @hook_around_blueprint
          ctx.object = object
          @hooks.around(:around_blueprint, ctx) do |ctx|
            config.options = ctx.options.freeze
            _serialize(config, ctx.object, instances:, store:, depth:, ctx: field_ctx)
          end
        else
          _serialize(config, object, instances:, store:, depth:, ctx: field_ctx)
        end
      end

      # Long and ugly for performance
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def _serialize(config, object, instances:, store:, depth:, ctx: nil)
        ctx&.object = object
        parent = nil
        # rubocop:disable Metrics/BlockLength
        config.fields.each_with_object({}) do |field, result|
          ctx&.field = field
          next if field._has_conditional && FieldLogic.skip?(ctx, field)

          # extract value
          if (field_hook = @field_hooks[field.type])
            value = catch SIGNAL do
              @hooks.around(field_hook, ctx) do
                val = field._extractor.extract(field, object, ctx:)
                field._has_default ? FieldLogic.value_or_default(field, val, ctx:) : val
              end
            end
            next if value == SIG_SKIP
          else
            value = field._extractor.extract(field, object, ctx:)
            value = FieldLogic.value_or_default(field, value, ctx:) if field._has_default
          end

          # format/serialize and set value
          result[field.name] =
            if value.nil?
              field._merged_options[:exclude_if_nil] ? next : nil
            elsif field.type == :field
              @format ? @formatter.call(config.blueprint, value) : value
            else
              parent ||= Context::Parent.new(@blueprint_class)
              parent.field = field
              parent.object = object
              field._serializer.serialize(field.blueprint, value, config.options, parent:, instances:, store:,
                                                                                  depth: depth + 1)
            end
        end
        # rubocop:enable Metrics/BlockLength
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

      # Runs any `around_blueprint_init` hooks on this Blueprint and returns the configuration that should be used.
      # The `around_blueprint_init` hooks may modify the blueprint's options or fields (for that render only).
      #
      # Only runs the FIRST time a given Blueprint is used during a given render.
      #
      # @param blueprint [Blueprinter::V2::Base] The Blueprint instance
      # @param options [Hash] Options given to `render`
      # @param store [Hash] The context store for this render
      # @param depth [Integer] Current serialization depth
      # @return [Blueprinter::V2::Serializer::Config]
      def blueprint_init(instances, options, store:, depth:)
        blueprint = instances.blueprint(@blueprint_class)
        config = Config.new(blueprint:, fields: default_fields, options:, needs_field_ctx: @needs_field_ctx)

        if @hook_around_blueprint_init
          fields = config.fields.map(&:to_configurable)
          ctx = Context::Init.new(blueprint, fields, options, store, depth)
          @hooks.around(:around_blueprint_init, ctx, require_yield: true) do |ctx|
            changed = ctx.blueprint.options != @blueprint_class.options
            config.blueprint.options.freeze
            config.fields = ctx.fields.map do |f|
              changed ||= f.changed?
              changed ? f.to_internal : f._original
            end.freeze

            if changed
              finalize_fields! config.fields, config.blueprint.options
              config.needs_field_ctx = needs_field_ctx? config.fields
            end
          end
        end

        config.options.freeze
        config
      end

      # Save time by skipping hooks that aren't used
      def find_used_hooks!
        @hook_around_serialize_object = @hooks.registered? :around_serialize_object
        @hook_around_serialize_collection = @hooks.registered? :around_serialize_collection
        @hook_around_blueprint = @hooks.registered? :around_blueprint
        @hook_around_blueprint_init = @hooks.registered? :around_blueprint_init
        @field_hooks = {
          field: @hooks.registered?(:around_field_value) ? :around_field_value : nil,
          object: @hooks.registered?(:around_object_value) ? :around_object_value : nil,
          collection: @hooks.registered?(:around_collection_value) ? :around_collection_value : nil
        }.freeze
      end

      # Skip Context::Field allocation when no field hooks, conditionals, callable defaults, or Proc extractors are in play
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def needs_field_ctx?(fields)
        @field_hooks.values.any? || fields.any? do |f|
          default = f._merged_options[:default]
          f._has_conditional || !!f._merged_options[:default_if] || default.is_a?(Proc) || default.is_a?(Symbol) ||
            (!!f.value_proc && f.value_proc.arity != 0 && f.value_proc.arity != 1)
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def finalize_fields!(fields, blueprint_opts)
        fields.each do |field|
          next if field.frozen?

          # copy blueprint options down to each field (faster b/c we can check exactly one Hash)
          field._merged_options = field.options.dup
          field._merged_options[:if] ||= blueprint_opts[:if] if blueprint_opts.key? :if
          field._merged_options[:unless] ||= blueprint_opts[:unless] if blueprint_opts.key? :unless
          field._merged_options[:default_if] ||= blueprint_opts[:default_if] if blueprint_opts.key? :default_if
          field._merged_options[:default] = blueprint_opts[:default] if blueprint_opts.key?(:default) &&
                                                                        !field.options.key?(:default)
          field._merged_options[:exclude_if_nil] = blueprint_opts[:exclude_if_nil] if blueprint_opts.key?(:exclude_if_nil) &&
                                                                                      !field.options.key?(:exclude_if_nil)

          # precompute some checks
          field._extractor = field.value_proc ? Extractors::Proc : Extractors::Property
          field._has_conditional = field._merged_options.key?(:if) || field._merged_options.key?(:unless)
          field._has_default = field._merged_options.key?(:default)
          field._serializer = field_serializer(field) if field.association?

          # freeze everything
          field.options.freeze
          field._merged_options.freeze
          field.source_str.freeze
          field.freeze
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def field_serializer(field)
        if field.blueprint.is_a? Proc
          field.collection? ? FieldSerializers::ProcCollection : FieldSerializers::ProcObject
        elsif field.blueprint < ::Blueprinter::Base
          FieldSerializers::V1Association
        else
          field.collection? ? FieldSerializers::Collection : FieldSerializers::Object
        end
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
