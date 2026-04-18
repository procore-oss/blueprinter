# frozen_string_literal: true

module Blueprinter
  module V2
    module FieldLogic
      # @param ctx [Blueprinter::V2::Context::Field]
      def self.skip?(ctx, blueprint, field)
        if (cond = field.options[:if])
          result = cond.is_a?(Proc) \
            ? blueprint.instance_exec(ctx, &cond) \
            : blueprint.public_send(cond, ctx)
          return true unless result
        end

        if (cond = field.options[:unless])
          result = cond.is_a?(Proc) \
            ? blueprint.instance_exec(ctx, &cond) \
            : blueprint.public_send(cond, ctx)
          return true if result
        end

        false
      end

      # @param ctx [Blueprinter::V2::Context::Field]
      def self.value_or_default(ctx, blueprint, field, value)
        default_if = field.options[:default_if]
        return value unless value.nil? || (default_if && use_default?(default_if, value, ctx))

        case (default_value = field.options[:default])
        when Proc then blueprint.instance_exec(value, ctx, &default_value)
        when Symbol then blueprint.public_send(default_value, value, ctx)
        else default_value
        end
      end

      # @param ctx [Blueprinter::V2::Context::Field]
      def self.use_default?(cond, value, ctx)
        case cond
        when Proc then ctx.blueprint.instance_exec(value, ctx, &cond)
        else ctx.blueprint.public_send(cond, value, ctx)
        end
      end
    end
  end
end
