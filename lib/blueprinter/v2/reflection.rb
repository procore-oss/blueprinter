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
        eval! unless evaled?
        @_reflections ||= flatten_children(self, :default).freeze
      end

      # Builds a flat Hash of nested views
      # @api private
      def flatten_children(parent, child_name, path = [])
        ref_key = path.empty? ? child_name : path.join('.').to_sym
        child_view = parent[child_name]
        child_view.eval!
        child_ref = View.new(child_view.spec, ref_key)

        child_view.spec.view_defs.reduce({ ref_key => child_ref }) do |acc, (name, _)|
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
        # @return [Hash] Options defined on the view or inherited from the parent
        attr_reader :options
        # @return [Hash<Symbol, Blueprinter::V2::Fields::Field>] Fields defined on the view
        attr_reader :extensions
        # @return [Array<Blueprinter::V2::Extension>] Extensions defined on the view
        attr_reader :fields
        # @return [Hash<Symbol, Blueprinter::V2::Fields::Field>] Associations to single objects defined on the view
        attr_reader :objects
        # @return [Hash<Symbol, Blueprinter::V2::Fields::Field>] Associations to collections defined on the view
        attr_reader :collections
        # @return [Hash<Symbol, Blueprinter::V2::Fields::Field>] All associations defined on the view
        attr_reader :associations
        # @return [Array<Blueprinter::V2::Fields::Field>]
        # All fields, objects, and collections in the order they were defined
        attr_reader :ordered

        # @param blueprint [Class] A subclass of Blueprinter::V2::Base
        # @param name [Symbol] Name of the view
        # @api private
        def initialize(spec, name)
          @name = name
          @options = spec.options
          @extensions = spec.extensions
          @ordered = spec.schema.values.freeze
          @fields = ordered.select(&:field?).to_h { |f| [f.name, f] }.freeze
          @objects = ordered.select(&:object?).to_h { |f| [f.name, f] }.freeze
          @collections = ordered.select(&:collection?).to_h { |f| [f.name, f] }.freeze
          @associations = objects.merge(collections).freeze
        end
      end
    end
  end
end
