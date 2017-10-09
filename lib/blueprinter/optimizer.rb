module Blueprinter
  class Optimizer
    class << self
      def optimize!(object, fields:)
        return object unless active_record_relation?(object)
        select_columns = (active_record_attributes_for(object) &
                         fields.map(&:method)) +
                         required_lookup_attributes_for(object)
        object.select(*select_columns)
      end

      private

      def active_record_relation?(object)
        !!(defined?(ActiveRecord::Relation) &&
          object.is_a?(ActiveRecord::Relation))
      end

      def active_record_attributes_for(object)
        object.klass.column_names.map(&:to_sym)
      end

      def required_lookup_attributes_for(object)
        # TODO: We may not need all four of these
        lookup_values = (object.includes_values +
                         object.preload_values +
                         object.joins_values +
                         object.eager_load_values).uniq
        lookup_values.map {|value| object.reflections[value.to_s].foreign_key}
      end
    end
  end
end
