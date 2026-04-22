# frozen_string_literal: true

module Blueprinter
  module V2
    # API for reflecting on Blueprints
    module Reflection
      #
      # Returns a Hash of views keyed by name.
      #
      # @return [Hash<Symbol, Blueprinter::V2::Reflection::View>]
      #
      def reflections
        eval! unless @serializer
        @_reflections ||= flatten_children(self, :default).freeze
      end

      # Builds a flat Hash of nested views
      # @api private
      def flatten_children(parent, child_name, path = [])
        ref_key = path.empty? ? child_name : path.join('.').to_sym
        child_view = parent.views.fetch(child_name)
        child_ref = View.new(child_view, ref_key)

        child_view.views.reduce({ ref_key => child_ref }) do |acc, (name, _)|
          children = name == :default ? {} : flatten_children(child_view, name, path + [name])
          acc.merge(children)
        end
      end

      #
      # Represents a view within a Blueprint.
      #
      class View
        # @return [Symbol] Name of the view
        attr_reader :name
        # @return [Hash<Symbol, Blueprinter::V2::Fields::Field>] Fields defined on the view
        attr_reader :fields
        # @return [Hash<Symbol, Blueprinter::V2::Fields::Object>] Associations to single objects defined on the view
        attr_reader :objects
        # @return [Hash<Symbol, Blueprinter::V2::Fields::Collection>] Associations to collections defined on the view
        attr_reader :collections
        # @return [Hash<Symbol, Blueprinter::V2::Fields::Object | Blueprint::V2::Fields::Collection>] All associations
        # defined on the view
        attr_reader :associations
        # @return [Array<Blueprinter::V2::Fields::Field|Blueprinter::V2::Fields::Object|Blueprinter::V2::Fields::Collection>]
        # All fields, objects, and collections in the order they were defined
        attr_reader :ordered

        # @param blueprint [Class] A subclass of Blueprinter::V2::Base
        # @param name [Symbol] Name of the view
        # @api private
        def initialize(blueprint, name)
          @name = name
          @ordered = reflected_fields(blueprint)
          @fields = ordered.select(&:field?).to_h { |f| [f.name, f] }.freeze
          @objects = ordered.select(&:object?).to_h { |f| [f.name, f] }.freeze
          @collections = ordered.select(&:collection?).to_h { |f| [f.name, f] }.freeze
          @associations = objects.merge(collections).freeze
        end

        private

        def reflected_fields(blueprint)
          blueprint.schema.values.map do |f|
            attrs = [f.name, f.from, f.from_str, f.value_proc, f.original_options]
            case f.type
            when :collection then Collection.new(*attrs, f.blueprint)
            when :object then Object.new(*attrs, f.blueprint)
            else Field.new(*attrs)
            end.freeze
          end.freeze
        end
      end

      # A non-object, non-collection field definition.
      #
      # @!attribute [r] name
      #   @return [Symbol] Name of field in result
      # @!attribute [r] from
      #   @return [Symbol] Method name/Hash key to pull the field value from
      # @!attribute [r] from_str
      #   @return [String] Same as `from` but a string
      # @!attribute [r] value_proc
      #   @return [Proc|NilClass] A proc to extract the value
      # @!attribute [r] options
      #   @return [Hash] Options defined on the field
      Field = Struct.new(
        :name,
        :from,
        :from_str,
        :value_proc,
        :options
      ) do
        include Fields::Helpers

        # @return [Symbol] :field
        def type = :field
      end

      # An object field definition.
      #
      # @!attribute [r] name
      #   @return [Symbol] Name of field in result
      # @!attribute [r] from
      #   @return [Symbol] Method name/Hash key to pull the field value from
      # @!attribute [r] from_str
      #   @return [String] Same as `from` but a string
      # @!attribute [r] value_proc
      #   @return [Proc|NilClass] A proc to extract the value
      # @!attribute [r] options
      #   @return [Hash] Options defined on the field
      # @!attribute [r] blueprint
      #   @return [Class] Blueprint to serialize with
      Object = Struct.new(
        :name,
        :from,
        :from_str,
        :value_proc,
        :options,
        :blueprint
      ) do
        include Fields::Helpers

        # @return [Symbol] :object
        def type = :object
      end

      # A collection field definition.
      #
      # @!attribute [r] name
      #   @return [Symbol] Name of field in result
      # @!attribute [r] from
      #   @return [Symbol] Method name/Hash key to pull the field value from
      # @!attribute [r] from_str
      #   @return [String] Same as `from` but a string
      # @!attribute [r] value_proc
      #   @return [Proc|NilClass] A proc to extract the value
      # @!attribute [r] options
      #   @return [Hash] Options defined on the field
      # @!attribute [r] blueprint
      #   @return [Class] Blueprint to serialize with
      Collection = Struct.new(
        :name,
        :from,
        :from_str,
        :value_proc,
        :options,
        :blueprint
      ) do
        include Fields::Helpers

        # @return [Symbol] :collection
        def type = :collection
      end
    end
  end
end
