# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # An extension to add a `:view` option to `render`, like V1 has.
    #
    # While V2's design makes the option unnecessary, having it can make upgrading from V1 easier.
    #
    # ```
    # class ApplicationBlueprint < Blueprinter::V2::Base
    #   extensions << Blueprinter::Extensions::ViewOption.new
    # end
    # ```
    #
    # Now these two `render` calls are equivalent:
    #
    #   WidgetBlueprint[:extended].render(widget)       # V2 style
    #   WidgetBlueprint.render(widget, view: :extended) # V1 style
    #
    class ViewOption < Extension
      # @param ctx [Blueprinter::V2::Context::Result]
      # @!visibility private
      def around_result(ctx)
        if (view = ctx.options[:view])
          ctx.blueprint = ctx.blueprint.class[view].new
          ctx.options = ctx.options.except(:view).freeze
        end
        yield ctx
      end

      # @!visibility private
      def hidden? = true
    end
  end
end
