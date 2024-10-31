# frozen_string_literal: true

module Blueprinter
  module V2
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
      # @yield [TODO] Generate the value from the block
      # @return [Blueprinter::V2::Field]
      #
      def field(name, from: name, **options, &definition)
        schema[name.to_sym] = Field.new(
          name: name,
          from: from,
          value_proc: definition,
          options: options.dup
        )
      end

      #
      # Add multiple fields at once.
      #
      def fields(*names)
        names.each do |name|
          schema[name.to_sym] = Field.new(name: name, options: {})
        end
      end

      #
      # Define an association to a single object.
      #
      # @param name [Symbol] Name of the association
      # @param blueprint [Class|Proc] Blueprint class to use, or one defined with a Proc
      # @param from [Symbol] Optionally specify a different method to call to get the value for "name"
      # @yield [TODO] Generate the value from the block
      # @return [Blueprinter::V2::ObjectField]
      #
      def object(name, blueprint, from: name, **options, &definition)
        schema[name.to_sym] = ObjectField.new(
          name: name,
          blueprint: blueprint,
          from: from,
          value_proc: definition,
          options: options.dup
        )
      end

      #
      # Define an association to a collection of objects.
      #
      # @param name [Symbol] Name of the association
      # @param blueprint [Class|Proc] Blueprint class to use, or one defined with a Proc
      # @param from [Symbol] Optionally specify a different method to call to get the value for "name"
      # @yield [TODO] Generate the value from the block
      # @return [Blueprinter::V2::Collection]
      #
      def collection(name, blueprint, from: name, **options, &definition)
        schema[name.to_sym] = Collection.new(
          name: name,
          blueprint: blueprint,
          from: from,
          value_proc: definition,
          options: options.dup
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
