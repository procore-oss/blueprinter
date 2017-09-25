module Blueprinter
  class Optimizer
    def initialize(object)
      @object = object
    end

    def select(fields)
      return object unless active_record_relation?
      select_columns = (active_record_attributes & fields.map(&:method)) +
                       required_lookup_attributes
      object.select(*select_columns)
    end

    private

    attr_reader :object

    def active_record_relation?
      !!defined?(ActiveRecord::Relation) &&
        object.is_a?(ActiveRecord::Relation)
    end

    def active_record_attributes
      object.klass.column_names.map(&:to_sym)
    end

    def required_lookup_attributes
      # TODO: We may not need all four of these
      lookup_values = (object.includes_values +
                       object.preload_values +
                       object.joins_values +
                       object.eager_load_values).uniq
      lookup_values.map {|value| object.reflections[value.to_s].foreign_key}
    end
  end
end
