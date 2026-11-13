# frozen_string_literal: true

module Blueprinter
  module V2
    #
    # Compiles each of a Blueprint's fields into a proc that reads the field's value off an object and writes it
    # into the result Hash.
    #
    # Everything a field's behavior depends on -- a condition, a default, `exclude_if_nil`, a formatter, a field
    # hook, whether it's an association -- is settled when the Blueprint is evaluated, so it's decided once here
    # instead of being re-tested for every field of every object. The procs are built once per Serializer and never
    # rebuilt: `around_blueprint_init` runs before this, and nothing after it can change a field.
    #
    # Each proc is called with `(result, object, frame)` and is responsible for writing (or not writing) one key.
    #
    # rubocop:disable-next Metrics/ClassLength
    # @!visibility private
    class Compiler
      # @param blueprint_class [Class]
      # @param formatter [Blueprinter::V2::Formatter]
      # @param hooks [Blueprinter::Hooks]
      # @param field_hooks [Hash<Symbol, Symbol | nil>] Field hook name by field type, if one is registered
      def initialize(blueprint_class:, formatter:, hooks:, field_hooks:)
        @blueprint_class = blueprint_class
        @formatter = formatter.any? ? formatter : nil
        @hooks = hooks
        @field_hooks = field_hooks
      end

      # @param fields [Array<Blueprinter::V2::Fields::Field>]
      # @return [Array<Proc>] One proc per field, in the order they'll be serialized
      def compile(fields)
        fields.map { |field| compile_field(field) }.freeze
      end

      private

      def compile_field(field)
        return compile_association(field) if field.association?
        return compile_plain(field) if plain?(field)

        compile_value(field)
      end

      # True if the field is a bare attribute read: no condition, default, `exclude_if_nil`, block, or field hook.
      # The great majority of fields are, and they compile to a read and a Hash write with nothing else in the way.
      def plain?(field)
        field._if.nil? && field._unless.nil? && !field._has_default && !field._exclude_if_nil &&
          field.block.nil? && @field_hooks[:field].nil?
      end

      # rubocop:disable-next Metrics/MethodLength, Metrics/PerceivedComplexity
      def compile_plain(field)
        name = field.name
        source = field.source
        source_str = field.source_str
        formatter = @formatter

        if formatter
          lambda { |result, object, frame|
            value =
              if object.is_a?(Hash)
                object.key?(source) ? object[source] : object[source_str]
              else
                object.public_send(source)
              end
            result[name] = value.nil? ? nil : formatter.call(frame.blueprint, value)
          }
        else
          lambda { |result, object, _frame|
            result[name] =
              if object.is_a?(Hash)
                object.key?(source) ? object[source] : object[source_str]
              else
                object.public_send(source)
              end
          }
        end
      end

      # rubocop:disable Metrics/BlockLength, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

      # A field that needs some combination of a condition, a default, `exclude_if_nil`, a block, a formatter, or a
      # field hook. Each of those is a captured local here rather than a Struct read and a branch per object.
      def compile_value(field)
        name = field.name
        source = field.source
        source_str = field.source_str
        block = field.block
        if_cond = field._if
        if_proc = if_cond.is_a?(Proc)
        unless_cond = field._unless
        unless_proc = unless_cond.is_a?(Proc)
        has_default = field._has_default
        default = field._default
        default_proc = default.is_a?(Proc)
        default_sym = default.is_a?(Symbol)
        default_if = field._default_if
        default_if_proc = default_if.is_a?(Proc)
        exclude_if_nil = field._exclude_if_nil
        formatter = @formatter
        hook = @field_hooks[:field]
        hooks = @hooks

        lambda { |result, object, frame|
          ctx = frame.ctx
          ctx.field = field if ctx

          next if if_cond && !(if_proc ? if_cond.call(ctx) : ctx.blueprint.public_send(if_cond, ctx))
          next if unless_cond && (unless_proc ? unless_cond.call(ctx) : ctx.blueprint.public_send(unless_cond, ctx))

          defaulted = false
          if hook
            value = catch(Serializer::SIGNAL) do
              hooks.around(hook, ctx) do
                val = block ? block.call(object, ctx) : Compiler.read(object, source, source_str)
                if has_default &&
                   (default_if ? Compiler.default?(default_if, default_if_proc, ctx, val) : val.nil?)
                  defaulted = true
                  Compiler.default_value(default, default_proc, default_sym, ctx)
                else
                  val
                end
              end
            end
            next if value == Serializer::SIG_SKIP
          else
            value = block ? block.call(object, ctx) : Compiler.read(object, source, source_str)
            if has_default && (default_if ? Compiler.default?(default_if, default_if_proc, ctx, value) : value.nil?)
              defaulted = true
              value = Compiler.default_value(default, default_proc, default_sym, ctx)
            end
          end

          if value.nil?
            next if exclude_if_nil

            result[name] = nil
          elsif defaulted || formatter.nil?
            result[name] = value
          else
            result[name] = formatter.call(frame.blueprint, value)
          end
        }
      end

      # An object or collection association. The value is handed to another Blueprint's Serializer, so this also
      # maintains the parent reference and the options handed down to it.
      def compile_association(field)
        name = field.name
        source = field.source
        source_str = field.source_str
        block = field.block
        blueprint = field.blueprint
        serializer = field._serializer
        blueprint_class = @blueprint_class
        if_cond = field._if
        if_proc = if_cond.is_a?(Proc)
        unless_cond = field._unless
        unless_proc = unless_cond.is_a?(Proc)
        has_default = field._has_default
        default = field._default
        default_proc = default.is_a?(Proc)
        default_sym = default.is_a?(Symbol)
        default_if = field._default_if
        default_if_proc = default_if.is_a?(Proc)
        exclude_if_nil = field._exclude_if_nil
        hook = @field_hooks[field.type]
        hooks = @hooks

        lambda { |result, object, frame|
          ctx = frame.ctx
          ctx.field = field if ctx

          next if if_cond && !(if_proc ? if_cond.call(ctx) : ctx.blueprint.public_send(if_cond, ctx))
          next if unless_cond && (unless_proc ? unless_cond.call(ctx) : ctx.blueprint.public_send(unless_cond, ctx))

          defaulted = false
          if hook
            value = catch(Serializer::SIGNAL) do
              hooks.around(hook, ctx) do
                val = block ? block.call(object, ctx) : Compiler.read(object, source, source_str)
                if has_default &&
                   (default_if ? Compiler.default?(default_if, default_if_proc, ctx, val) : val.nil?)
                  defaulted = true
                  Compiler.default_value(default, default_proc, default_sym, ctx)
                else
                  val
                end
              end
            end
            next if value == Serializer::SIG_SKIP
          else
            value = block ? block.call(object, ctx) : Compiler.read(object, source, source_str)
            if has_default && (default_if ? Compiler.default?(default_if, default_if_proc, ctx, value) : value.nil?)
              defaulted = true
              value = Compiler.default_value(default, default_proc, default_sym, ctx)
            end
          end

          if value.nil?
            next if exclude_if_nil

            result[name] = nil
          elsif defaulted
            # A default value is used as-is, not run through the association's Blueprint
            result[name] = value
          else
            config = frame.config
            parent = frame.parent ||= Context::Parent.new(blueprint_class)
            parent.field = field
            parent.object = object
            # A field hook may have replaced the options for this association only, so hand those down and reset
            assoc_options = ctx ? ctx.options : config.options
            ctx.options = config.options if ctx && !assoc_options.equal?(config.options)
            result[name] = serializer.serialize(blueprint, value, assoc_options, parent:,
                                                                                 instances: frame.instances,
                                                                                 store: frame.store,
                                                                                 depth: frame.depth + 1)
          end
        }
      end

      # rubocop:enable Metrics/BlockLength, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

      class << self
        # Read `source` off an object or Hash. Mirrors Fields::Field#extract.
        def read(object, source, source_str)
          if object.is_a?(Hash)
            object.key?(source) ? object[source] : object[source_str]
          else
            object.public_send(source)
          end
        end

        def default?(default_if, is_proc, ctx, value)
          is_proc ? !!default_if.call(ctx, value) : !!ctx.blueprint.public_send(default_if, ctx, value)
        end

        def default_value(default, is_proc, is_sym, ctx)
          if is_proc
            default.call(ctx)
          elsif is_sym
            ctx.blueprint.public_send(default, ctx)
          else
            default
          end
        end
      end
    end
  end
end
