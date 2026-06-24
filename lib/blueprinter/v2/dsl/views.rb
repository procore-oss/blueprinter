# frozen_string_literal: true

module Blueprinter
  module V2
    module DSL
      module Views
        #
        # Define a new child view, which is a subclass of self. If a view with this name already exists, the definition will
        # be appended.
        #
        # @param name [Symbol] Name of the view
        # @yield Define the view in the block
        #
        def view(name, &definition)
          name = name.to_sym
          raise Errors::InvalidBlueprint, 'You may not redefine the default view' if name == :default
          raise Errors::InvalidBlueprint, "View name may not contain '.'" if name.to_s =~ /\./

          partial(name, &definition)
          nodes << Nodes::View.new(name, definition)
        end

        #
        # Define a new partial. If a partial with this name already exists, it will be replaced.
        #
        # @param name [Symbol] Name of the partial to create or import
        # @yield Define a new partial in the block
        #
        def partial(name, &definition)
          nodes << Nodes::Partial.new(name.to_sym, definition)
        end

        #
        # Include one or more partials.
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
