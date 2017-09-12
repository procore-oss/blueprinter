module PaintedRabbit
  class ViewCollection
    attr_reader :views
    def initialize
      @views = {
        identifier: View.new,
        default: View.new
      }
    end

    def has_view?(view_name)
      views.has_key? view_name
    end

    def fields_for(view_name)
      identifier_fields + sortable_fields(view_name).sort_by(&:name)
    end

    def [](view_name)
      @views[view_name] ||= View.new
    end

    private

    def identifier_fields
      views[:identifier].fields
    end

    def sortable_fields(view_name)
      fields = views[:default].fields
      fields += views[view_name].fields
      views[view_name].included_view_names.each do |included_view_name|
        if view_name != included_view_name
          fields += sortable_fields(included_view_name)
        end
      end
      fields.delete_if do |f|
        views[view_name].excluded_field_names.include? f.name
      end
    end
  end
end
