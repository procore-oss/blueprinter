# frozen_string_literal: true

module Blueprinter
  #
  # Public methods for reflecting on a Blueprint.
  #
  module Reflection
    Field = Struct.new(:name, :display_name, :options)
    Association = Struct.new(:name, :display_name, :blueprint, :view, :options)

    #
    # Returns a Hash of views keyed by name.
    #
    # Example:
    #
    #   widget_view = WidgetBlueprint.reflections[:default]
    #   category = widget_view.associations[:category]
    #   category.blueprint
    #   => CategoryBlueprint
    #   category.view
    #   => :default
    #
    # @return [Hash<Symbol, Blueprinter::Reflection::View>]
    #
    def reflections
      @_reflections ||= view_collection.views.transform_values do |view|
        View.new(view.name, view_collection)
      end
    end

    #
    # Represents a view within a Blueprint.
    #
    class View
      attr_reader :name

      def initialize(name, view_collection)
        @name = name
        @view_collection = view_collection
      end

      #
      # Returns a Hash of fields in this view (recursive) keyed by method name.
      #
      # @return [Hash<Symbol, Blueprinter::Reflection::Field>]
      #
      def fields
        @_fields ||= @view_collection.fields_for(name).each_with_object({}) do |field, obj|
          next if field.options[:association]

          obj[field.name] = Field.new(field.method, field.name, field.options)
        end
      end

      #
      # Returns a Hash of associations in this view (recursive) keyed by method name.
      #
      # @return [Hash<Symbol, Blueprinter::Reflection::Association>]
      #
      def associations
        @_associations ||= @view_collection.fields_for(name).each_with_object({}) do |field, obj|
          next unless field.options[:association]

          blueprint = field.options.fetch(:blueprint)
          view = field.options[:view] || :default
          obj[field.name] = Association.new(field.method, field.name, blueprint, view, field.options)
        end
      end
    end
  end
end
