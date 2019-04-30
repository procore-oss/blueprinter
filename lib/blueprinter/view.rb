module Blueprinter
  # @api private
  class View
    attr_reader :excluded_field_names, :fields, :included_view_names, :name, :excluded_view_names

    def initialize(name, fields: {}, included_view_names: [], excluded_field_names: [],excluded_view_names: [])
      @name = name
      @fields = fields
      @included_view_names = included_view_names
      @excluded_field_names = excluded_field_names
      @excluded_view_names =  excluded_view_names
    end

    def inherit(view)
      view.fields.values.each do |field|
        self << field
      end

      view.included_view_names.each do |view_name|
        include_view(view_name)
      end

      view.excluded_field_names.each do |field_name|
        exclude_field(field_name)
      end

      view.excluded_view_names.each do |view_name|
        exclude_view(view_name)
      end
    end

    def include_view(view_name)
      included_view_names << view_name
    end

    def exclude_view(view_name)
      excluded_view_names << view_name
    end

    def exclude_field(field_name)
      excluded_field_names << field_name
    end

    def exclude_fields(field_names)
      field_names.each do |field_name|
        excluded_field_names << field_name
      end
    end

    def <<(field)
      fields[field.name] = field
    end
  end
end
