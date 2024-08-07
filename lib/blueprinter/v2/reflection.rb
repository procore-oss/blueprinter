# frozen_string_literal: true

module Blueprinter
  class V2
    # API for reflecting on Blueprints
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
        # @return [Hash<Symbol, Blueprinter::V2::Field>] Fields defined on the view
        attr_reader :fields
        # @return [Hash<Symbol, Blueprinter::V2::Association>] Associations defined on the view
        attr_reader :associations

        def initialize(blueprint)
          @name = blueprint.view_name
          @fields = blueprint.fields.select { |_, f| f.is_a? Field }
          @associations = blueprint.fields.select { |_, f| f.is_a? Association }
        end
      end
    end
  end
end
