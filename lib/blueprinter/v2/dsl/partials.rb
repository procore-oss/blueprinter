# frozen_string_literal: true

require 'set'

module Blueprinter
  module V2
    module DSL
      # Create and use composable partials.
      module Partials
        #
        # Define a partial. Partials are composable blocks with access to the full DSL: fields,
        # associations, formatters, options, extensions, views, and even partials. Use them to share
        # code between views or Blueprints.
        #
        # ```
        # class WidgetBlueprint < ApplicationBlueprint
        #   fields :id, :name
        #
        #   view :short do
        #     use :associations
        #     field(:description) { |ctx| ctx.object.description[0..50] }
        #   end
        #
        #   view :expanded do
        #     use :associations
        #     field :description
        #   end
        #
        #   partial :associations do
        #     association :category, CategoryBlueprint
        #     association :parts, [PartBlueprint]
        #   end
        # end
        # ```
        #
        # NOTE: Defining a 2nd partial with the same name overrides the first.
        #
        # == Partials in modules
        #
        # You may define partials in external Ruby modules, then use them in your Blueprints and views:
        #
        # ```
        # module MyPartials
        #   extend Blueprinter::V2::DSL
        #
        #   partial :my_partial do
        #     # ...
        #   end
        # end
        #
        # class MyBlueprint
        #   include MyPartials
        #
        #   use :my_partial
        #   # ...
        # end
        # ```
        #
        # @param name [Symbol] Name of the partial to create
        # @yield Define the partial in the block. It has access to the full DSL.
        #
        def partial(name, &definition)
          nodes << Nodes::Partial.new(name.to_sym, definition)
        end
      end
    end
  end
end
