# frozen_string_literal: true

module Blueprinter
  module V2
    module DSL
      module Views
        #
        # Define a child view, which inherits everything from the parent including fields, associations,
        # formatters, options, partials, and extensions.
        #
        # Views can be nested to an arbitrary depth. They can define fields, associations, formatters, options,
        # extensions, partials, and nested views.
        #
        # If a view with this name already exists, the definition will be appended.
        #
        # ```
        # class WidgetBlueprint < ApplicationBlueprint
        #   fields :id, :name
        #
        #   # This view will contain :id, :name, and :description
        #   view :extended do
        #     field :description
        #
        #     # This view (:"extended.plus") will contain :id, :name, :description, and :parts
        #     view :plus do
        #       collection :parts, [PartBlueprint]
        #     end
        #   end
        #
        #   # This view will only contain :id
        #   view :id_only do
        #     exclude fields: true
        #     field :id
        #   end
        # end
        # ```
        #
        # @param name [Symbol] Name of the view
        # @yield Define the view in the block. It has access to the full DSL.
        #
        def view(name, &definition)
          name = name.to_sym
          raise Errors::InvalidBlueprint, 'You may not redefine the default view' if name == :default
          raise Errors::InvalidBlueprint, "View name may not contain '.'" if name.to_s =~ /\./

          partial(name, &definition)
          nodes << Nodes::View.new(name, definition)
        end

        #
        # Define a partial. Partials can define anything Blueprints or views can: fields,
        # associations, formatters, options, extensions, views, and other partials. But they're not
        # views. Rather, views can `use` partials as shared functionality, similar to how Ruby classes
        # can include modules.
        #
        # If a partial with this name already exists, it will be **replaced**.
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
        # @param name [Symbol] Name of the partial to create or import
        # @yield Define the partial in the block. It has access to the full DSL.
        #
        def partial(name, &definition)
          nodes << Nodes::Partial.new(name.to_sym, definition)
        end

        #
        # Include one or more partials in the current context.
        #
        # ```
        # view :foo do
        #   use :my_partial
        # end
        # ```
        #
        # NOTE: `use` expands in-place, so ordering can matter. Preceding lines can be overridden by the partial,
        # while subsequent lines can override what's in the partial.
        #
        # NOTE: Anytime you create a view, a partial of the same name is also created. This allows views to `use`
        # other views just like partials.
        #
        # @param *names [Symbol] One or more partial names
        # @param exclude [Array<Symbol>] Names of fields or associations to exclude from the partial(s)
        # @param fields [true | false] If false, no fields from the partial(s) will be used
        # @param options [true | false] If false, no options from the partial(s) will be used
        # @param extensions [true | false] If false, no extensions from the partial(s) will be used
        # @param formatters [true | false] If false, no formatters from the partial(s) will be used
        #
        def use(*names, exclude: [], fields: true, options: true, extensions: true, formatters: true)
          callsite = caller[0]
          exclusions = Specification::Exclusions.new(
            field_names: Set.new(exclude), fields: !fields, options: !options, extensions: !extensions,
            formatters: !formatters
          )
          names.each do |name|
            nodes << Nodes::Use.new(name.to_sym, exclusions, callsite)
          end
        end
      end
    end
  end
end
