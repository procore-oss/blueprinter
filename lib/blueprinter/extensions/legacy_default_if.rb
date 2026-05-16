# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # Support for Legacy/V1's `default_if` options.
    #
    class LegacyDefaultIf < Extension
      # @param ctx [Blueprinter::V2::Context::Init]
      # @!visibility private
      def around_blueprint_init(ctx)
        if (default_if = ctx.blueprint.options[:default_if])
          ctx.blueprint.options[:default_if] = convert_v1(default_if)
        end

        ctx.fields.each do |field|
          if (default_if = field.options[:default_if])
            field.options[:default_if] = convert_v1(default_if)
          end
        end

        yield ctx
      end

      private

      def convert_v1(cond)
        case cond
        when ::Blueprinter::EMPTY_COLLECTION, ::Blueprinter::EMPTY_HASH, ::Blueprinter::EMPTY_STRING
          ->(_ctx, value) { EmptyTypes.send(:use_default_value?, value, cond) }
        else
          cond
        end
      end
    end
  end
end
