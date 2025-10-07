# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # An optional, built-in extension for a ":view" option on render.
    #
    class ViewOption < Extension
      # @param ctx [Blueprinter::V2::Context::Render]
      def blueprint(ctx)
        if (view = ctx.options[:view])
          ctx.blueprint.class[view]
        else
          ctx.blueprint.class
        end
      end

      def hidden? = true
    end
  end
end
