module Blueprinter
  # @api private
  class ViewCollection
    attr_reader :views
    def initialize
      @views = {
        identifier: View.new(:identifier),
        default: View.new(:default)
      }
    end

    def inherit(view_collection)
      view_collection.views.each do |view_name, view|
        self[view_name].inherit(view)
      end
    end

    def has_view?(view_name)
      views.has_key? view_name
    end

    def fields_for(view_name)
      sorted_fields = sortable_fields(view_name).values
      unless Blueprinter.configuration.sort_by_definition
        sorted_fields = sorted_fields.sort_by(&:name)
      end
      identifier_fields + sorted_fields
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
