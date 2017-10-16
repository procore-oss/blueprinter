module Blueprinter
  # @api private
  class View
    attr_reader :fields, :included_view_names, :excluded_field_names

    def initialize(name)
      @name = name
      @fields = {}
      @included_view_names = []
      @excluded_field_names = []
    end

    def include_view(view_name)
      @included_view_names << view_name
    end

    def exclude_field(field_name)
      @excluded_field_names << field_name
    end

    def <<(field)
      if @fields.has_key? field
        raise BlueprinterError,
          "Field #{field.name} already defined on #{@name}"
      end
      @fields[field.name] = field
    end
  end
end
