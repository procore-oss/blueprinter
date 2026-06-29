# frozen_string_literal: true

module Blueprinter
  module V2
    module DSL
      module Data
        # @!visibility private
        BLUEPRINT_ARRAY_OR_CLASS_ERR = 'Blueprint must be a Blueprint class or an Array containing a Blueprint class'

        #
        # Add a formatter for field values of the given class.
        #
        # @param klass [Class] The class of objects to format
        # @param formatter_method [Symbol] Name of a public instance method to call for formatting
        # @yield Do formatting in the block instead
        #
        def format(klass, formatter_method = nil, &formatter_block)
          nodes << Nodes::Format.new(klass, formatter_method&.to_sym || formatter_block)
        end

        #
        # Define a field.
        #
        # @param name [Symbol] Name of the field
        # @param source [Symbol] Optionally specify a different method/Hash key to call to get the value for "name"
        # @param default [Object | Symbol | Proc] Value to use if the field is nil, or if `default_if` returns true
        # @param default_if [Symbol | Proc] Return true to use the value in `default`
        # @param exclude_if_nil [Boolean] Don't include field if the value is nil
        # @param if [Symbol | Proc] Only include the field if it returns true
        # @param unless [Symbol | Proc] Include the field unless it returns true
        # @yield [Blueprinter::V2::Context] Generate the value from the block
        #
        def field(name, source: name, **options, &definition)
          name = name.to_sym
          nodes << Fields::Field.new(
            type: :field,
            name: name,
            source: source.to_sym,
            source_str: source.to_s,
            value_proc: definition,
            options: options.dup
          )
        end

        #
        # Add multiple fields at once.
        #
        # @param name [Symbol] Name of the field
        # @param default [Object | Symbol | Proc] Value to use if the field is nil, or if `default_if` returns true
        # @param default_if [Symbol | Proc] Return true to use the value in `default`
        # @param exclude_if_nil [Boolean] Don't include field if the value is nil
        # @param if [Symbol | Proc] Only include the field if it returns true
        # @param unless [Symbol | Proc] Include the field unless it returns true
        # @yield [Blueprinter::V2::Context] Generate the value from the block
        #
        def fields(*names, **options, &definition)
          names.each do |name|
            name = name.to_sym
            nodes << Fields::Field.new(
              type: :field,
              name: name,
              source: name,
              source_str: name.to_s,
              options: options,
              value_proc: definition
            )
          end
        end

        #
        # Defines an association to an object or collection.
        #
        # @param name [Symbol] Name of the association
        # @param blueprint [Class|Proc|Array<Class|Proc>] Blueprint class to use. For a collection, wrap the blueprint in an
        #                  array. You may also pass a Proc that returns a Blueprint.
        # @param source [Symbol] Optionally specify a different method/Hash key to call to get the value for "name"
        # @param default [Object | Symbol | Proc] Value to use if the field is nil, or if `default_if` returns true
        # @param default_if [Symbol | Proc] Return true to use the value in `default`
        # @param exclude_if_nil [Boolean] Don't include field if the value is nil
        # @param if [Symbol | Proc] Only include the field if it returns true
        # @param unless [Symbol | Proc] Include the field unless it returns true
        # @yield [Blueprinter::V2::Context] Generate the value from the block
        #
        def association(name, blueprint, source: name, **options, &definition)
          name = name.to_sym
          is_collection, blueprint_class = parse_blueprint(blueprint)
          nodes << Fields::Field.new(
            type: is_collection ? :collection : :object,
            name: name,
            blueprint: blueprint_class,
            source: source.to_sym,
            source_str: source.to_s,
            value_proc: definition,
            options: options.dup
          )
        end

        #
        # Excludes the given fields and associations from parent Blueprints or views. Or categorically exclude things.
        #
        # Note: Does **not** affect fields, options, etc. coming from partials.
        #
        # @param *names [Symbol] Fields or associations to exclude
        # @param fields [true | false] Exclude all fields
        # @param options [true | false] Exclude all options
        # @param extensions [true | false] Exclude all extensions
        # @param formatters [true | false] Exclude all formatters
        #
        def exclude(*names, fields: false, options: false, extensions: false, formatters: false)
          names.each { |name| nodes << Nodes::Exclude.new(name.to_sym) }
          nodes << Nodes::Flag.new(:exclude_fields) if fields
          nodes << Nodes::Flag.new(:exclude_options) if options
          nodes << Nodes::Flag.new(:exclude_extensions) if extensions
          nodes << Nodes::Flag.new(:exclude_formatters) if formatters
        end

        alias excludes exclude

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
          raise ArgumentError, BLUEPRINT_ARRAY_OR_CLASS_ERR unless is_bp_class || assoc_arg.is_a?(Proc)

          [is_collection, assoc_arg]
        end
      end
    end
  end
end
