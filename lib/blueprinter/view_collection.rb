module Blueprinter
  # @api private
  class ViewCollection
    attr_reader :views, :sort_by_definition
    def initialize
      @views = {
        identifier: View.new(:identifier),
        default: View.new(:default)
      }
      @sort_by_definition = Blueprinter.configuration.sort_fields_by.eql?(:definition)
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
      fields = sortable_fields(view_name).values
      sorted_fields = sort_by_definition ? fields : fields.sort_by(&:name)
      identifier_fields + sorted_fields
    end

    def [](view_name)
      @views[view_name] ||= View.new(view_name)
    end

    private

    def identifier_fields
      views[:identifier].fields.values
    end
    
    def default_fields
      views[:default].fields
    end

    def sortable_fields(view_name)
      fields = merge_fields(default_fields,views[view_name].fields)
      views[view_name].included_view_names.each do |included_view_name|
        if view_name != included_view_name
          fields = merge_fields(fields, sortable_fields(included_view_name))
        end
      end

      remove_fields(fields,views[view_name].excluded_field_names)

      views[view_name].excluded_view_names.each do |excluded_view_name|
        next if view_name == excluded_view_name
        fields_to_exclude = sortable_fields(excluded_view_name).keys
        fields_to_exclude = fields_to_exclude - default_fields.keys if excluded_view_name != :default 
        remove_fields(fields,fields_to_exclude)
      end

      fields
    end

    def remove_fields(field_list,exclude_list)
      exclude_list.each {|name| field_list.delete(name) }
    end


    def merge_fields(source_fields, included_fields)
      if sort_by_definition
        included_fields.merge(source_fields)
      else
        source_fields.merge(included_fields)
      end
    end
  end
end
