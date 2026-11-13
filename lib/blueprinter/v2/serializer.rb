# frozen_string_literal: true

require 'blueprinter/v2/formatter'
require 'blueprinter/hooks'

module Blueprinter
  module V2
    # rubocop:disable-next Metrics/ClassLength
    # @!visibility private
    class Serializer
      SIGNAL = :_blueprinter_signal
      SIG_SKIP = :_blueprinter_signal_skip

      # Blueprint instance & options for a given render. The fields are fixed when the Blueprint is evaluated, so
      # they're held on the Serializer rather than here.
      #
      # @!attribute [r] blueprint
      #   @return [Blueprinter::V2::Base] Instance of Blueprint to use during a render
      # @!attribute [r] options
      #   @return [Hash] Options Hash given to `render`
      Config = Struct.new(:blueprint, :options, keyword_init: true)

      attr_reader :hooks

      def initialize(blueprint_class)
        spec = blueprint_class.spec
        @blueprint_class = blueprint_class
        @formatter = Formatter.new(spec.formatters)
        @format = @formatter.any?
        @hooks = Hooks.new([Extensions::Core::Format.new, *spec.extensions, Extensions::Core::Root.new])
        @default_fields = finalize_fields(spec.schema.values, spec.options)
        find_used_hooks!
        @needs_field_ctx = needs_field_ctx? @default_fields
      end

      # Serialize a single object.
      #
      # @param object [Object] The object to serialize
      # @param options [Hash] Options passed to `render`
      # @param instances [Blueprinter::V2::InstanceCache] Instance cache for this render
      # @param store [Hash] The store for this render
      # @param depth [Integer] Current serialization depth
      # @param parent [Blueprinter::V2::Context::Parent] Reference to the parent object (if depth > 1)
      # @return [Hash] The serialized value for `object`
      def object(object, options, instances:, store:, depth: 1, parent: nil)
        # The Config is built once per Blueprint per render, but extensions may change the options between objects,
        # so refresh them when the caller hands down a different Hash.
        config = store[@blueprint_class.object_id] ||= blueprint_init(instances, options)
        config.options = options.freeze unless config.options.equal? options
        field_ctx = @needs_field_ctx ? build_field_ctx(config, store:, depth:) : nil
        blueprint_ctx = @hook_around_blueprint ? build_object_ctx(config, parent:, store:, depth:) : nil

        if @hook_around_serialize_object
          ctx = build_object_ctx(config, object:, parent:, store:, depth:)
          @hooks.around(:around_serialize_object, ctx) do |ctx|
            config.options = ctx.options.freeze
            refresh_options(config.options, blueprint_ctx, field_ctx)
            serialize(config, ctx.object, instances:, store:, depth:, field_ctx:, ctx: blueprint_ctx)
          end
        else
          serialize(config, object, instances:, store:, depth:, field_ctx:, ctx: blueprint_ctx)
        end
      end

      # Serialize a collection of objects.
      #
      # @param objects [Enumerable<Object>] The objects to serialize
      # @param options [Hash] Options passed to `render`
      # @param instances [Blueprinter::V2::InstanceCache] Instance cache for this render
      # @param store [Hash] The store for this render
      # @param depth [Integer] Current serialization depth
      # @param parent [Blueprinter::V2::Context::Parent] Reference to the parent object (if depth > 1)
      # @return [Array<Hash>] The serialized value for `objects`
      def collection(objects, options, instances:, store:, depth: 1, parent: nil)
        # See the note in `object` about refreshing options
        config = store[@blueprint_class.object_id] ||= blueprint_init(instances, options)
        config.options = options.freeze unless config.options.equal? options
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

      # The fields defined on this Blueprint/view in the order they were defined.
      #
      # @return [Array<Blueprinter::V2::Fields>]
      attr_reader :default_fields

      private

      def serialize_collection(config, objects, parent:, instances:, store:, depth:)
        ctx = @hook_around_blueprint ? build_object_ctx(config, parent:, store:, depth:) : nil
        field_ctx = @needs_field_ctx ? build_field_ctx(config, store:, depth:) : nil

        objects.map do |object|
          serialize(config, object, instances:, store:, depth:, field_ctx:, ctx:)
        end.to_a
      end

      # Context objects hold their own reference to the options, so they must be refreshed when a hook changes them
      def refresh_options(options, ctx_a, ctx_b = nil)
        ctx_a&.options = options
        ctx_b&.options = options
      end

      def build_field_ctx(config, store:, depth:)
        Context::Field.new(config.blueprint, @default_fields, config.options, nil, nil, store, depth)
      end

      def build_object_ctx(config, store:, depth:, object: nil, parent: nil)
        Context::Object.new(config.blueprint, @default_fields, config.options, object, parent, store, depth)
      end

      def serialize(config, object, instances:, store:, depth:, ctx: nil, field_ctx: nil)
        if @hook_around_blueprint
          ctx.object = object
          @hooks.around(:around_blueprint, ctx) do |ctx|
            config.options = ctx.options.freeze
            refresh_options(config.options, field_ctx)
            _serialize(config, ctx.object, instances:, store:, depth:, ctx: field_ctx)
          end
        else
          _serialize(config, object, instances:, store:, depth:, ctx: field_ctx)
        end
      end

      # Long and ugly for performance
      # rubocop:disable-next Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def _serialize(config, object, instances:, store:, depth:, ctx: nil)
        ctx&.object = object
        parent = nil
        # `each_with_object` would allocate an extra object per serialized object, so build the Hash by hand
        result = {}
        # rubocop:disable-next Metrics/BlockLength
        @default_fields.each do |field|
          ctx&.field = field
          next if field._has_conditional && FieldLogic.skip?(ctx, field)

          # extract value
          defaulted = false
          if @any_field_hooks && (field_hook = @field_hooks[field.type])
            value = catch SIGNAL do
              @hooks.around(field_hook, ctx) do
                val = field.block ? field.block.call(object, ctx) : field.extract(object)
                if field._has_default && FieldLogic.default?(field, val, ctx:)
                  defaulted = true
                  FieldLogic.default_value(field, ctx:)
                else
                  val
                end
              end
            end
            next if value == SIG_SKIP
          else
            value = field.block ? field.block.call(object, ctx) : field.extract(object)
            if field._has_default && FieldLogic.default?(field, value, ctx:)
              defaulted = true
              value = FieldLogic.default_value(field, ctx:)
            end
          end

          # format/serialize and set value
          result[field.name] =
            if value.nil?
              field._exclude_if_nil ? next : nil
            elsif defaulted
              value
            elsif field.type == :field
              @format ? @formatter.call(config.blueprint, value) : value
            else
              parent ||= Context::Parent.new(@blueprint_class)
              parent.field = field
              parent.object = object
              # A field hook may have replaced the options for this association only, so hand those down and reset
              assoc_options = ctx ? ctx.options : config.options
              ctx.options = config.options unless assoc_options.equal? config.options
              field._serializer.serialize(field.blueprint, value, assoc_options, parent:, instances:, store:,
                                                                                 depth: depth + 1)
            end
        end
        result
      end

      # Builds the configuration for this Blueprint for a given render.
      #
      # Only runs the FIRST time a given Blueprint is used during a given render.
      #
      # @param instances [Blueprinter::V2::InstanceCache]
      # @param options [Hash] Options given to `render`
      # @return [Blueprinter::V2::Serializer::Config]
      def blueprint_init(instances, options)
        Config.new(blueprint: instances.blueprint(@blueprint_class), options: options.freeze)
      end

      # Save time by skipping hooks that aren't used
      def find_used_hooks!
        @hook_around_serialize_object = @hooks.registered? :around_serialize_object
        @hook_around_serialize_collection = @hooks.registered? :around_serialize_collection
        @hook_around_blueprint = @hooks.registered? :around_blueprint
        @field_hooks = {
          field: @hooks.registered?(:around_field_value) ? :around_field_value : nil,
          object: @hooks.registered?(:around_object_value) ? :around_object_value : nil,
          collection: @hooks.registered?(:around_collection_value) ? :around_collection_value : nil
        }.freeze
        # Lets the render path skip the per-field lookup above when no field hooks are registered (the common case)
        @any_field_hooks = @field_hooks.each_value.any?
      end

      # Skip Context::Field allocation when no field hooks, conditionals, callable defaults, or Proc extractors are in play
      # rubocop:disable-next Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def needs_field_ctx?(fields)
        @any_field_hooks || fields.any? do |f|
          f._has_conditional || !!f._default_if || f._default.is_a?(Proc) || f._default.is_a?(Symbol) ||
            (!!f.block && f.block.arity != 0 && f.block.arity != 1)
        end
      end

      # Returns frozen copies of `fields` with `blueprint_opts` merged into them.
      #
      # The Field objects in `spec.schema` are the same objects the parent Blueprint and its other views
      # inherited, and each of those has its own options, so the merged values can't be written back onto them.
      # Every Serializer gets its own copies instead.
      def finalize_fields(fields, blueprint_opts)
        fields.map { |field| finalize_field(field, blueprint_opts) }.freeze
      end

      # rubocop:disable-next Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Style/DoubleNegation
      def finalize_field(field, blueprint_opts)
        opts = field.options
        final = field.dup

        # copy field or blueprint options into struct members (faster than Hash lookups)
        final._if = opts[:if] || blueprint_opts[:if]
        final._unless = opts[:unless] || blueprint_opts[:unless]
        final._default_if = opts[:default_if] || blueprint_opts[:default_if]
        final._has_default = opts.key?(:default) || blueprint_opts.key?(:default)
        final._default = opts.key?(:default) ? opts[:default] : blueprint_opts[:default]
        final._exclude_if_nil = opts.key?(:exclude_if_nil) ? opts[:exclude_if_nil] : blueprint_opts[:exclude_if_nil]

        # precompute some checks
        final._has_conditional = !!(final._if || final._unless)
        final._serializer = field_serializer(final) if final.association?

        # freeze everything (`options` and `source_str` are shared with the declared field)
        final.options.freeze
        final.source_str.freeze
        final.freeze
      end

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
  end
end
