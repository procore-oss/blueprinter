# frozen_string_literal: true

module Blueprinter
  class V2
    module Reflection
      def self.extended(klass)
        klass.class_eval do
          private_class_method :flattened_views
        end
      end

      #
      # Returns a Hash of views keyed by name.
      #
      # @return [Hash<Symbol, Blueprinter::V2::Reflection::View>]
      #
      def reflections
        @reflections ||= flattened_views(views)
      end

      # Builds a flat Hash of nested views
      def flattened_views(views, acc = {})
        views.each_with_object(acc) do |(_, blueprint), obj|
          obj[blueprint.view_name] = View.new(blueprint)
          children = blueprint.views.except(:default)
          flattened_views(children, obj)
        end
      end

      #
      # Represents a view within a Blueprint.
      #
      class View
        # @return [Symbol] Name of the view
        attr_reader :name
        # @return [Hash<Symbol, TODO>] Fields defined on the view
        attr_reader :fields
        # @return [Hash<Symbol, TODO>] Associations defined on the view
        attr_reader :associations

        def initialize(blueprint)
          @name = blueprint.view_name
          @fields = {} # TODO: get non-association fields from blueprint.fields
          @associations = {} # TODO: get association fields from blueprint.fields
        end
      end
    end
  end
end
