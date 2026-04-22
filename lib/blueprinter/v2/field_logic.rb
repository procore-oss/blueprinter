# frozen_string_literal: true

module Blueprinter
  module V2
    module FieldLogic
      # Returns true if the field should be skipped. Based on the return value of field-level or Blueprint-level
      # "if" and "unless" options.
      #
      # @param ctx [Blueprinter::V2::Context::Field]
      # @param field [Blueprinter::V2::Fields] Internal field definition (has extra, private, attrs)
      # @return [True|False]
      def self.skip?(ctx, field)
        if (cond = field.options[:if])
          result = cond.is_a?(Proc) ? ctx.blueprint.instance_exec(ctx, &cond) : ctx.blueprint.public_send(cond, ctx)
          return true unless result
        end

        if (cond = field.options[:unless])
          result = cond.is_a?(Proc) ? ctx.blueprint.instance_exec(ctx, &cond) : ctx.blueprint.public_send(cond, ctx)
          return true if result
        end

        false
      end

      # Returns the given value or a default value. Default values are pulled from the field-level or Blueprint-level
      # "default" option. It will be used if the given value is nil or if the "default_if" option evaluates truthy.
      #
      # @param ctx [Blueprinter::V2::Context::Field]
      # @param field [Blueprinter::V2::Fields] Internal field definition (has extra, private, attrs)
      # @param value [Object] The current field value
      # @return [Object] The final field value
      def self.value_or_default(ctx, field, value)
        default_if = field.options[:default_if]
        return value unless value.nil? || (default_if && use_default?(default_if, value, ctx))

        case (default_value = field.options[:default])
        when Proc then ctx.blueprint.instance_exec(value, ctx, &default_value)
        when Symbol then ctx.blueprint.public_send(default_value, value, ctx)
        else default_value
        end
      end

      # Returns true if a default value should be used.
      #
      # @param cond [Proc|Symbol]
      # @param value [Object] The current field value
      # @param ctx [Blueprinter::V2::Context::Field]
      # @return [True|False]
      def self.use_default?(cond, value, ctx)
        case cond
        when Proc then ctx.blueprint.instance_exec(value, ctx, &cond)
        else ctx.blueprint.public_send(cond, value, ctx)
        end
      end
    end
  end
end
