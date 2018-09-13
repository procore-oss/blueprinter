module Blueprinter
  # @api private
  module View
    class FieldMap
      attr_reader :excluded_fields, :fields

      def initialize
        @fields = { identifier: [], default: [] }
        @excluded_fields = {}
      end

      def exclude(field_name, from:)
        view = from
        excluded_fields[view] = excluded_fields.fetch(view, []) + [field_name]
        self
      end

      def add(field, to:)
        view = to
        fields[view] = fields.fetch(view, []) + [field]
        self
      end

      def set(field, to:)
        view = to
        fields[view] = [field]
      end
    end
  end
end
