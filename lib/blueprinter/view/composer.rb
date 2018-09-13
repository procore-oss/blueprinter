module Blueprinter
  # @api private
  module View
    class Composer

      def initialize(builder)
        @ancestors = builder.ancestors
        @composed = {}
      end

      def compose(field_map)
        fields = field_map.fields
        excluded_fields = field_map.excluded_fields
        self.composed = ancestors.inject({}) do |acc, (view, ancestor_views)|
          acc[view] = ancestor_views.inject([]) do |arr, ancestor_view|
            arr += fields.fetch(ancestor_view, [])
            arr.delete_if do |field|
              excluded_fields.fetch(ancestor_view, []).include? field.method
            end
            arr
          end.sort_by { |f| [fields[:identifier].include?(f) ? 0 : 1, f.name] }
          acc
        end
      end

      def composed_fields_for(view)
        composed[view]
      end

      private

      attr_reader :ancestors
      attr_accessor :composed
    end
  end
end
