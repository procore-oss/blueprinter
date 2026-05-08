# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # Support for Legacy/V1's legacy conditionals. V2 continue to work.
    #
    class LegacyConditionals < Extension
      # @!visibility private
      V1_ARITY = 3

      # @param ctx [Blueprinter::V2::Context::Init]
      # @!visibility private
      def around_blueprint_init(ctx)
        # Convert blueprint if/unless options
        ctx.blueprint_options[:if] = convert_v1(ctx.blueprint_options[:if]) if ctx.blueprint_options[:if]
        ctx.blueprint_options[:unless] = convert_v1(ctx.blueprint_options[:unless]) if ctx.blueprint_options[:unless]

        # Convert field if/unless options
        ctx.fields.each do |field|
          field.options[:if] = convert_v1(field.options[:if]) if field.options[:if]
          field.options[:unless] = convert_v1(field.options[:unless]) if field.options[:unless]
        end

        yield ctx
      end

      private

      def convert_v1(cond)
        if cond.arity == V1_ARITY
          ->(ctx) { cond.call(ctx.field.source, ctx.object, ctx.options) }
        else
          cond
        end
      end
    end
  end
end
