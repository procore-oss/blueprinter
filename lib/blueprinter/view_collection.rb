module Blueprinter
  class ViewCollection
    attr_reader :views
    def initialize
      @views = {
        identifier: View.new(:identifier),
        default: View.new(:default)
      }
    end

    def has_view?(view_name)
      views.has_key? view_name
    end

    def fields_for(view_name)
      identifier_fields + sortable_fields(view_name).values.sort_by(&:name)
    end

    def [](view_name)
      @views[view_name] ||= View.new(view_name)
    end

    private

    def identifier_fields
      views[:identifier].fields.values
    end

    def sortable_fields(view_name)
      fields = views[:default].fields
      fields = fields.merge(views[view_name].fields)
      views[view_name].included_view_names.each do |included_view_name|
        if view_name != included_view_name
          fields = fields.merge(sortable_fields(included_view_name))
        end
      end

      views[view_name].excluded_field_names.each do |name|
        fields.delete(name)
      end

      fields
    end
  end
end
