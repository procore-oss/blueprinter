# frozen_string_literal: true

require 'blueprinter/v2/compiler/source'

module Blueprinter
  module V2
    #
    # Generates the Ruby source for a Blueprint's `_serialize` method.
    #
    # Everything a field's behavior depends on -- a condition, a default, `exclude_if_nil`, a formatter, a field
    # hook, whether it's an association -- is settled when the Blueprint is evaluated. Rather than re-testing all
    # of that for every field of every object, each field is compiled down to only the steps it actually uses.
    #
    # This runs once per Blueprint, and nothing can change a field afterward: `around_blueprint_init` is an init
    # hook that has already run by this point.
    #
    # == Reading this class
    #
    # {#compile_field} lists the steps a field goes through, in the order they happen at render time. Each step is
    # a method below that emits nothing at all when the field doesn't use it, so a plain field compiles to a single
    # Hash write and a field with a condition, a default and a formatter compiles to four lines.
    #
    # The steps emit through a {Source}, which handles indentation and `end` keywords. The only strings the steps
    # build themselves are *expressions*, and each of those has its own `_expr` method.
    #
    # == Values that aren't literals
    #
    # Procs, Blueprint classes and the formatter can't be written as Ruby literals, so they're collected into
    # {Compiled#constants} and referenced as `c[0]`, `c[1]`. Field names and sources *are* emitted as literals, via
    # `inspect`, so that each read is a send to a literal Symbol.
    #
    # Read {Compiled#source} to see what a Blueprint compiled to; it's also what backtraces point at.
    #
    # rubocop:disable-next Metrics/ClassLength
    # @!visibility private
    class Compiler
      # @!attribute [r] source
      #   @return [String] Ruby source defining `_serialize(frame, object)`
      # @!attribute [r] constants
      #   @return [Array] Values the source refers to as `c[n]`
      # @!attribute [r] filename
      #   @return [String] What to tell `eval`, so backtraces name the Blueprint
      Compiled = Struct.new(:source, :constants, :filename)

      SIGNAL = '::Blueprinter::V2::Serializer::SIGNAL'
      SIG_SKIP = '::Blueprinter::V2::Serializer::SIG_SKIP'
      PARENT = '::Blueprinter::V2::Context::Parent'

      # The value being worked on, and whether it came from a `default`
      VALUE = '_v'
      DEFAULTED = '_d'

      # @param blueprint_class [Class]
      # @param formatter [Blueprinter::V2::Formatter]
      # @param hooks [Blueprinter::Hooks]
      # @param field_hooks [Hash<Symbol, Symbol | nil>] Field hook name by field type, if one is registered
      def initialize(blueprint_class:, formatter:, hooks:, field_hooks:)
        @blueprint_class = blueprint_class
        @formatter = formatter.any? ? formatter : nil
        @hooks = hooks
        @field_hooks = field_hooks
        @constants = []
        @const_index = {}
      end

      # @param fields [Array<Blueprinter::V2::Fields::Field>]
      # @return [Blueprinter::V2::Compiler::Compiled]
      def compile(fields)
        code = Source.new
        code.open 'def _serialize(frame, object)' do
          code.assign 'c', '@compiled_constants'
          code.assign 'ctx', 'frame.ctx'
          code.line 'ctx.object = object if ctx'
          code.assign 'result', '{}'
          fields.each { |field| compile_field field, code }
          code.line 'result'
        end
        Compiled.new(code.to_s, @constants.freeze, "(blueprinter)#{@blueprint_class}")
      end

      private

      #
      # What a field does, in the order it happens
      #

      def compile_field(field, code)
        return write_bare_read(field, code) if bare_read?(field)

        # Conditions can read `ctx.field`, so it's set before them rather than inside them
        code.line "ctx.field = #{const field} if ctx"
        code.if_ condition_expr(field) do
          code.assign DEFAULTED, 'false' if track_defaulted?(field)
          read_value field, code
          # A field hook may have called `skip!`, which abandons the field entirely
          code.unless_ skipped_expr(field) do
            apply_format field, code
            serialize_association field, code
            write_result field, code
          end
        end
      end

      # The common case: no condition, default, formatter, hook, block or `exclude_if_nil`. Just a read and a
      # write, with no temporary in between.
      # rubocop:disable-next Metrics/CyclomaticComplexity
      def bare_read?(field)
        field._if.nil? && field._unless.nil? && !field._has_default && !field._exclude_if_nil &&
          field.block.nil? && @field_hooks[field.type].nil? && @formatter.nil? && !field.association?
      end

      def write_bare_read(field, code)
        code.assign "result[#{field.name.inspect}]", value_expr(field)
      end

      # Reads the field's value into `_v`, with any `default` applied. When a field hook is registered the whole
      # thing runs inside it, so the hook sees the defaulted value and may call `skip!`.
      def read_value(field, code)
        hook = @field_hooks[field.type]
        return read_and_default(field, code) unless hook

        code.open "#{VALUE} = catch(#{SIGNAL}) do" do
          code.open "#{const @hooks}.around(#{hook.inspect}, ctx) do" do
            read_and_default field, code
            code.line VALUE
          end
        end
      end

      def read_and_default(field, code)
        code.assign VALUE, value_expr(field)
        return unless field._has_default

        code.if_ default_test_expr(field) do
          code.assign VALUE, default_value_expr(field)
          code.assign DEFAULTED, 'true' if track_defaulted?(field)
        end
      end

      # Formatters don't run on a nil value or on one that came from a `default`
      def apply_format(field, code)
        return if @formatter.nil? || field.association?

        code.line "#{VALUE} = #{const @formatter}.call(frame.blueprint, #{VALUE}) unless #{untouched_expr field}"
      end

      # Hands an association's value to its Blueprint. A `default` is used as-is, not serialized.
      def serialize_association(field, code)
        return unless field.association?

        code.unless_ untouched_expr(field) do
          code.assign '_cfg', 'frame.config'
          code.assign '_p', "frame.parent ||= #{PARENT}.new(#{const @blueprint_class})"
          code.line "_p.field = #{const field}"
          code.line '_p.object = object'
          # A field hook may have replaced the options for this association only, so hand those down and reset
          code.assign '_ao', 'ctx ? ctx.options : _cfg.options'
          code.line 'ctx.options = _cfg.options if ctx && !_ao.equal?(_cfg.options)'
          code.assign VALUE, association_call_expr(field)
        end
      end

      # Writes `_v`, unless the field opted out of nils
      def write_result(field, code)
        guard = field._exclude_if_nil ? " unless #{VALUE}.nil?" : ''
        code.line "result[#{field.name.inspect}] = #{VALUE}#{guard}"
      end

      #
      # Expressions
      #

      # The field's raw value: its block, or a read off the object
      def value_expr(field)
        return "#{const field.block}.call(object, ctx)" if field.block

        key = field.source.inspect
        str = field.source_str.inspect
        "(object.is_a?(Hash) ? (object.key?(#{key}) ? object[#{key}] : object[#{str}]) : object.public_send(#{key}))"
      end

      # `if` and `unless` combined into one guard. `&&` short-circuits, so `unless` is only evaluated when `if`
      # passed, which is the order the uncompiled serializer used. Nil when the field has no conditions.
      def condition_expr(field)
        guards = []
        guards << callable_expr(field._if, 'ctx') if field._if
        guards << "!(#{callable_expr(field._unless, 'ctx')})" if field._unless
        guards.empty? ? nil : guards.join(' && ')
      end

      # True when a field hook abandoned the field. Nil when no hook is registered for this field type.
      def skipped_expr(field)
        @field_hooks[field.type] ? "#{VALUE} == #{SIG_SKIP}" : nil
      end

      # True when `_v` is nil or came from a `default`, i.e. nothing further should touch it
      def untouched_expr(field)
        track_defaulted?(field) ? "#{VALUE}.nil? || #{DEFAULTED}" : "#{VALUE}.nil?"
      end

      def default_test_expr(field)
        cond = field._default_if
        cond ? callable_expr(cond, "ctx, #{VALUE}") : "#{VALUE}.nil?"
      end

      def default_value_expr(field)
        default = field._default
        case default
        when Proc, Symbol then callable_expr(default, 'ctx')
        else const default
        end
      end

      def association_call_expr(field)
        "#{const field._serializer}.serialize(#{const field.blueprint}, #{VALUE}, _ao, parent: _p, " \
          'instances: frame.instances, store: frame.store, depth: frame.depth + 1)'
      end

      # A Proc is called; a Symbol is a method on the Blueprint instance
      def callable_expr(callable, args)
        if callable.is_a? Proc
          "#{const callable}.call(#{args})"
        else
          "ctx.blueprint.public_send(#{callable.inspect}, #{args})"
        end
      end

      #
      # Bookkeeping
      #

      # `_d` is only worth tracking when a later step treats a defaulted value differently
      def track_defaulted?(field)
        field._has_default && (field.association? || !@formatter.nil?)
      end

      # Adds a value the source can't express as a literal and returns the expression that reads it back
      def const(value)
        idx = @const_index[value.object_id] ||= begin
          @constants << value
          @constants.size - 1
        end
        "c[#{idx}]"
      end
    end
  end
end
