# frozen_string_literal: true

module Blueprinter
  module V2
    # Methods for defining Blueprint fields and views
    module DSL
      # @api private
      BLUEPRINT_ARRAY_OR_CLASS_ERR = 'Blueprint must be a Blueprint class or an Array containing a Blueprint class'

      #
      # Define a new child view, which is a subclass of self. If a view with this name already exists, the definition will be
      # appended.
      #
      # @param name [Symbol] Name of the view
      # @param empty [Boolean] Don't inherit fields from ancestors (default false)
      # @yield Define the view in the block
      #
      def view(name, empty: nil, &definition)
        raise Errors::InvalidBlueprint, "View name may not contain '.'" if name.to_s =~ /\./

        name = name.to_sym
        partials[name] = definition
        views[name] = ViewBuilder::Def.new(definition:, empty:)
      end

      #
      # Define a new partial. If a partial with this name already exists, it will be replaced.
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
      # Define an anonymous extension and add it to the current context. It will be initialized
      # once per render.
      #
      #   class WidgetBlueprint < ApplicationBlueprint
      #     extension do
      #       # modify every object before serialization
      #       def around_blueprint(ctx)
      #         object = modify ctx.object
      #         yield object
      #       end
      #     end
      #   end
      #
      def extension(&block)
        bp_name = blueprint_name
        extensions << Class.new(Extension) do
          @blueprint_name = bp_name
          def self.name = "#{@blueprint_name} extension"
          class_eval(&block)
        end
      end

      #
      # Define a field.
      #
      # @param name [Symbol] Name of the field
      # @param from [Symbol] Optionally specify a different method to call to get the value for "name"
      # @param extractor [Class] Extractor class to use for this field
      # @param default [Object | Symbol | Proc] Value to use if the field is nil, or if `default_if` returns true
      # @param default_if [Symbol | Proc] Return true to use the value in `default`
      # @param exclude_if_nil [Boolean] Don't include field if the value is nil
      # @param exclude_if_empty [Boolean] Don't include field if the value is nil or `empty?`
      # @param if [Symbol | Proc] Only include the field if it returns true
      # @param unless [Symbol | Proc] Include the field unless it returns true
      # @yield [Blueprinter::V2::Context] Generate the value from the block
      # @return [Blueprinter::V2::Fields::Field]
      #
      def field(name, from: name, **options, &definition)
        name = name.to_sym
        schema[name] = Fields::Field.new(
          name: name,
          from: from.to_sym,
          from_str: from.to_s,
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
          schema[name] = Fields::Field.new(name: name, from: name, from_str: name.to_s, options: {})
        end
      end

      #
      # Defines an association to an object or collection.
      #
      # @param name [Symbol] Name of the association
      # @param blueprint [Class|Array<Class>] Blueprint class to use (object). For a collection, wrap the blueprint in an
      # array.
      # @param from [Symbol] Optionally specify a different method to call to get the value for "name"
      # @param extractor [Class] Extractor class to use for this field
      # @param default [Object | Symbol | Proc] Value to use if the field is nil, or if `default_if` returns true
      # @param default_if [Symbol | Proc] Return true to use the value in `default`
      # @param exclude_if_nil [Boolean] Don't include field if the value is nil
      # @param exclude_if_empty [Boolean] Don't include field if the value is nil or `empty?`
      # @param if [Symbol | Proc] Only include the field if it returns true
      # @param unless [Symbol | Proc] Include the field unless it returns true
      # @yield [Blueprinter::V2::Context] Generate the value from the block
      #
      def association(name, blueprint, from: name, **options, &definition)
        name = name.to_sym
        is_collection, blueprint_class = parse_blueprint(blueprint)
        type = is_collection ? Fields::Collection : Fields::Object
        schema[name] = type.new(
          name: name,
          blueprint: blueprint_class,
          from: from.to_sym,
          from_str: from.to_s,
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

      private

      def parse_blueprint(blueprint)
        is_collection, assoc_arg =
          if blueprint.is_a? Array
            raise ArgumentError, BLUEPRINT_ARRAY_OR_CLASS_ERR unless blueprint.size == 1

            [true, blueprint[0]]
          else
            [false, blueprint]
          end

        is_bp_class = assoc_arg.is_a?(Class) && (assoc_arg < V2::Base || assoc_arg < Blueprinter::Base)
        raise ArgumentError, BLUEPRINT_ARRAY_OR_CLASS_ERR unless is_bp_class || assoc_arg.is_a?(ViewWrapper)

        [is_collection, assoc_arg]
      end
    end
  end
end
