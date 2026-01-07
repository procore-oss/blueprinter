# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # An optional, built-in extension for a ":view" option on render.
    #
    class ViewOption < Extension
      # @param ctx [Blueprinter::V2::Context::Result]
      def around_result(ctx)
        if (view = ctx.options[:view])
          ctx.blueprint = ctx.blueprint.class[view].new
          ctx.options = ctx.options.except(:view).freeze
        end
        yield ctx
      end

      def hidden? = true
    end
  end
end
