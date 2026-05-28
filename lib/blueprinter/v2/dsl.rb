# frozen_string_literal: true

module Blueprinter
  module V2
    # Methods for defining Blueprint fields and views
    module DSL
      # @!visibility private
      module Nodes
        Use = Struct.new(:name)
        Exclude = Struct.new(:name)
        Partial = Struct.new(:name, :block)
        Options = Struct.new(:block)
        Extensions = Struct.new(:block)
        Format = Struct.new(:klass, :fmt)
        Flag = Struct.new(:name)
      end

      # @api private
      BLUEPRINT_ARRAY_OR_CLASS_ERR = 'Blueprint must be a Blueprint class or an Array containing a Blueprint class'

      #
      # Define a new child view, which is a subclass of self. If a view with this name already exists, the definition will be
      # appended.
      #
      # @param name [Symbol] Name of the view
      # @yield Define the view in the block
      #
      def view(name, &definition)
        raise Errors::InvalidBlueprint, "View name may not contain '.'" if name.to_s =~ /\./

        name = name.to_sym
        partial(name, &definition)
        views[name] = definition
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
      #
      def use(*names)
        names.each do |name|
          nodes << Nodes::Use.new(name.to_sym)
        end
      end

      #
      # Modify options inside the block.
      #
      # @yield [Hash] Array of options that can be modified
      #
      def options(&block)
        raise BlueprinterError, "A block must be passed to 'options'" unless block

        nodes << Nodes::Options.new(block)
      end

      #
      # Modify extensions inside the block.
      #
      # @yield [Array] Array of extensions that can be modified
      #
      def extensions(&block)
        raise BlueprinterError, "A block must be passed to 'extensions'" unless block

        nodes << Nodes::Extensions.new(block)
      end

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
      # Define an anonymous extension and add it to the current context.
      #
      #   class WidgetBlueprint < ApplicationBlueprint
      #     extension do
      #       # modify every object before serialization
      #       def around_serialize_object(ctx)
      #         object = modify ctx.object
      #         yield object
      #       end
      #     end
      #   end
      #
      def extension(&block)
        bp_name = blueprint_name
        extensions do |exts|
          exts << Class.new(Extension) do
            @blueprint_name = bp_name
            def self.name = "#{@blueprint_name} extension"
            class_eval(&block)
          end.new
        end
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
      # Excludes the given fields and associations from parents or partials.
      #
      # @param *names [Symbol] One or more fields or associations to exclude
      #
      def exclude(*names)
        names.each do |name|
          nodes << Nodes::Exclude.new(name.to_sym)
        end
      end

      alias excludes exclude

      #
      # Excludes all fields and associations from parents or partials.
      #
      def exclude_all
        nodes << Nodes::Flag.new(:exclude_all)
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
        raise ArgumentError, BLUEPRINT_ARRAY_OR_CLASS_ERR unless is_bp_class || assoc_arg.is_a?(Proc)

        [is_collection, assoc_arg]
      end
    end
  end
end
