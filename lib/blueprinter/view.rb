module Blueprinter
  # @api private
  class View
    attr_reader :excluded_field_names, :fields, :included_view_names, :name

    def initialize(name, fields: {}, included_view_names: [], excluded_view_names: [])
      @name = name
      @fields = fields
      @included_view_names = included_view_names
      @excluded_field_names = excluded_view_names
    end

    def include_view(view_name)
      included_view_names << view_name
    end

    def exclude_field(field_name)
      excluded_field_names << field_name
    end

    def <<(field)
      if fields.has_key?(field.name)
        raise BlueprinterError,
          "Field #{field.name} already defined on #{name}"
      end
      fields[field.name] = field
    end
  end
end
