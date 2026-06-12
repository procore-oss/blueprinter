# frozen_string_literal: true

module Blueprinter
  module V2
    # Methods for defining Blueprint fields and views
    # rubocop:disable Metrics/ModuleLength
    module DSL
      # @!visibility private
      module Nodes
        Use = Struct.new(:name, :exclude, :fields, :options, :extensions, :formatters, :callsite, keyword_init: true)
        Exclude = Struct.new(:name)
        Partial = Struct.new(:name, :block)
        View = Struct.new(:name, :block)
        Format = Struct.new(:klass, :fmt)
        SetOpt = Struct.new(:key, :val)
        SetDynamicOpt = Struct.new(:key, :block)
        UnsetOpt = Struct.new(:key)
        AppendExt = Struct.new(:ext)
        PrependExt = Struct.new(:ext)
        RemExt = Struct.new(:klass)
        RemDynamicExt = Struct.new(:block)
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
        names.each do |name|
          nodes << Nodes::Use.new(name: name.to_sym, exclude:, fields:, options:, extensions:, formatters:, callsite:)
        end
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
        add Class.new(Extension) {
          @blueprint_name = bp_name
          def self.name = "#{@blueprint_name} extension"
          class_eval(&block)
        }.new
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

      #
      # Set an option value.
      #
      # @param key [Symbol] Option name
      # @param value [Object | nil] Object value
      # @yield [Object | nil] Get the current value then return the value you want
      #
      def set(key, value = nil, &block)
        node = block ? Nodes::SetDynamicOpt.new(key, block) : Nodes::SetOpt.new(key, value)
        nodes << node
      end

      #
      # Clear the given options.
      #
      # @param *keys [Symbol]
      #
      def unset(*keys)
        keys.each { |key| nodes << Nodes::UnsetOpt.new(key) }
      end

      #
      # Adds one or more extensions.
      #
      # @param *extensions [Blueprinter::Extension] Extension instances to add
      # @param prepend [true | false] Add this extension before all others
      #
      def add(*extensions, prepend: false)
        if block_given?
          raise BlueprinterError, 'Blueprinter::DSL#add does not accept a block. Did you mean to pass it to an extension?'
        end

        extensions.reverse! if prepend
        extensions.each do |ext|
          node = prepend ? Nodes::PrependExt.new(ext) : Nodes::AppendExt.new(ext)
          nodes << node
        end
      end

      #
      # Removes extensions of the given classes, or that satisfy the given block.
      #
      # @param *klasses [Class]
      # @yield [Blueprinter::Extension] Return true if the given extension should be removed
      #
      def remove(*klasses, &reject)
        klasses.each { |klass| nodes << Nodes::RemExt.new(klass) }
        nodes << Nodes::RemDynamicExt.new(reject) if reject
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
    # rubocop:enable Metrics/ModuleLength
  end
end
