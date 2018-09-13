require_relative 'builder'
require_relative 'composer'
require_relative 'field_map'

module Blueprinter
  # @api private
  module View
    class Manager

      def initialize
        @builder = Builder.new
        @composer = Composer.new(@builder)
        @field_map = FieldMap.new
      end

      def include(view, with:)
        ancestor_view = with
        builder.build(view, with: ancestor_view)
        composer.compose(field_map)
      end

      def exclude(field_name, from:)
        view = from
        field_map.exclude(field_name, from: view)
        composer.compose(field_map)
      end

      def add(field, to:)
        view = to
        builder.build(view) unless builder.include?(view)
        field_map.add(field, to: view)
        composer.compose(field_map)
      end

      def set(field, to:)
        view = to
        field_map.set(field, to: view)
        composer.compose(field_map)
      end

      def fields_for(view)
        composer.composed_fields_for(view)
      end

      private

      attr_reader :builder, :composer, :field_map
    end
  end
end
