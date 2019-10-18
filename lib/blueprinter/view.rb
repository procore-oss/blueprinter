module Blueprinter
  # @api private
  class View
    attr_reader :excluded_field_names, :fields, :included_view_names, :name, :transformers

    def initialize(name, fields: {}, included_view_names: [], excluded_view_names: [],transformers: [])
      @name = name
      @fields = fields
      @included_view_names = included_view_names
      @excluded_field_names = excluded_view_names
      @transformers =  transformers
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

      view.transformers.each do |transformer|
        self.add_transformer(transformer)
      end
    end

    def include_view(view_name)
      included_view_names << view_name
    end

    def include_views(view_names)
      view_names.each do |view_name|
        included_view_names << view_name
      end
    end

    def exclude_field(field_name)
      excluded_field_names << field_name
    end

    def exclude_fields(field_names)
      field_names.each do |field_name|
        excluded_field_names << field_name
      end
    end

    def add_transformer(custom_transformer)
      transformers << custom_transformer
    end

    def <<(field)
      fields[field.name] = field
    end
  end
end
