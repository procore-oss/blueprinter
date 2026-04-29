# frozen_string_literal: true

module Blueprinter
  module V2
    # API for reflecting on V2 Blueprints. See {Blueprinter::V2::Reflection::View} to see what you can do with each view.
    #
    #   # The default view
    #   view = WidgetBlueprint.reflections[:default]
    #
    #   # A custom view called :extended
    #   view = WidgetBlueprint.reflections[:extended]
    #
    #   # A nested view
    #   view = WidgetBlueprint.reflections[:extended][:plus]
    #
    # Alternatively you can first access the view you want, then it's reflections. The following two lines below access
    # the same view:
    #
    #   view1 = WidgetBlueprint.reflections[:extended][:plus]
    #   view2 = WidgetBlueprint[:extended].reflections[:plus]
    #   view1 == view2
    #
    # The :default view always refers to the "base" that `reflections` was called on.
    #
    #   view1 = WidgetBlueprint.reflections[:extended]
    #   view2 = WidgetBlueprint[:extended].reflections[:default]
    #   view1 == view2
    #
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
      # @!visibility private
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
        # @return [Hash] Options defined on the view or inherited from the parent
        attr_reader :options
        # @return [Hash<Symbol, Blueprinter::V2::Field>] Fields defined on the view
        attr_reader :fields
        # @return [Hash<Symbol, Blueprinter::V2::Field>] Associations to single objects defined on the view
        attr_reader :objects
        # @return [Hash<Symbol, Blueprinter::V2::Field>] Associations to collections defined on the view
        attr_reader :collections
        # @return [Hash<Symbol, Blueprinter::V2::Field>] All associations defined on the view
        attr_reader :associations
        # @return [Array<Blueprinter::V2::Field>]
        # All fields, objects, and collections in the order they were defined
        attr_reader :ordered

        # @param blueprint [Class] A subclass of Blueprinter::V2::Base
        # @param name [Symbol] Name of the view
        # @!visibility private
        def initialize(blueprint, name)
          @name = name
          @options = blueprint.options
          @ordered = blueprint.schema.values.freeze
          @fields = ordered.select(&:field?).to_h { |f| [f.name, f] }.freeze
          @objects = ordered.select(&:object?).to_h { |f| [f.name, f] }.freeze
          @collections = ordered.select(&:collection?).to_h { |f| [f.name, f] }.freeze
          @associations = objects.merge(collections).freeze
        end
      end
    end
  end
end
