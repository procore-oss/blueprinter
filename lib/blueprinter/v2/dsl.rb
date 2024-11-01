# frozen_string_literal: true

module Blueprinter
  module V2
    # Methods for defining Blueprint fields and views
    module DSL
      #
      # Define a new child view, which is a subclass of self.
      #
      # @param name [Symbol] Name of the view
      # @param fields [Boolean] Inherit fields from parents
      # @param options [Boolean] Inherit options from parents
      # @param extensions [Boolean] Inherit extensions from parents
      # @yield Define the view in the block
      #
      def view(name, fields: true, options: true, extensions: true, &definition)
        raise Errors::InvalidBlueprint, "View name may not contain '.'" if name.to_s =~ /\./

        name = name.to_sym
        partials[name] = definition
        views[name] = ViewBuilder::Def.new(definition:, fields:, options:, extensions:)
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
      # Append one or more partials to this view.
      #
      # @param names [Array<Symbol>] One or more partial names
      #
      def use(*names)
        names.each { |name| appended_partials << name.to_sym }
      end

      #
      # Insert one or more partials in this view.
      #
      # @param names [Array<Symbol>] One or more partial names
      #
      def use!(*names)
        names.each(&method(:apply_partial!))
      end

      #
      # Add a formatter for field values of the given class.
      #
      # @param klass [Class] The class of objects to format
      # @param formatter_method [Symbol] Name of a public instance method to call for formatting
      # @yield Do formatting in the block instead
      #
      def format(klass, formatter_method = nil, &formatter_block)
        formatters[klass] = formatter_method || formatter_block
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
        name = name.to_sym
        schema[name] = Field.new(
          name: name,
          from: from.to_sym,
          value_proc: definition,
          options: options.dup
        )
      end

      #
      # Add multiple fields at once.
      #
      def fields(*names)
        names.each do |name|
          name = name.to_sym
          schema[name] = Field.new(name: name, options: {})
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
        name = name.to_sym
        schema[name] = ObjectField.new(
          name: name,
          blueprint: blueprint,
          from: from.to_sym,
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
        name = name.to_sym
        schema[name] = Collection.new(
          name: name,
          blueprint: blueprint,
          from: from.to_sym,
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
