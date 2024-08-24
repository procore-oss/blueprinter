# frozen_string_literal: true

require 'blueprinter/v2/association'
require 'blueprinter/v2/field'

module Blueprinter
  class V2
    # Methods for defining Blueprint fields and views
    module DSL
      #
      # Define a new child view, which is a subclass of self.
      #
      # @param name [Symbol] Name of the view
      # @yield Define the view in the block
      #
      def view(name, &definition)
        raise Errors::InvalidBlueprint, "View name may not contain '.'" if name.to_s =~ /\./

        views[name.to_sym] = definition
      end

      #
      # Define a new partial.
      #
      # @param name [Symbol] Name of the partial to create or import
      # @yield Define a new partial in the block
      #
      def partial(name, &definition)
        partials[name.to_sym] = definition
      end

      #
      # Import a partial into this view.
      #
      # @param names [Array<Symbol>] One or more partial names
      #
      def use(*names)
        names.each { |name| used_partials << name.to_sym }
      end

      #
      # Define a field.
      #
      # @param name [Symbol] Name of the field
      # @param from [Symbol] Optionally specify a different method to call to get the value for "name"
      # @param if [Proc] Only include this field if the Proc evaluates to truthy
      # @yield [TODO] Generate the value from the block
      # @return [Blueprinter::V2::Field]
      #
      def field(name, from: name, **options, &definition)
        fields[name.to_sym] = Field.new(
          name: name,
          from: from,
          if_cond: options.delete(:if),
          value_proc: definition,
          custom_options: options
        )
      end

      #
      # Define an association.
      #
      # @param name [Symbol] Name of the association
      # @param blueprint [Class|Proc] Blueprint class to use, or one defined with a Proc
      # @param view [Symbol] Only for use with legacy (not V2) blueprints
      # @param from [Symbol] Optionally specify a different method to call to get the value for "name"
      # @param if [Proc] Only include this association if the Proc evaluates to truthy
      # @yield [TODO] Generate the value from the block
      # @return [Blueprinter::V2::Association]
      #
      def association(name, blueprint, from: name, view: nil, **options, &definition)
        raise ArgumentError, 'The :view argument may not be used with V2 Blueprints' if view && blueprint.is_a?(V2)

        fields[name.to_sym] = Association.new(
          name: name,
          blueprint: blueprint,
          legacy_view: view,
          from: from,
          if_cond: options.delete(:if),
          value_proc: definition,
          custom_options: options
        )
      end

      #
      # Exclude parent fields and associations from this view.
      #
      # @param name [Array<Symbol>] One or more fields or associations to exclude
      #
      def exclude(*names)
        self.excludes += names.map(&:to_sym)
      end
    end
  end
end
