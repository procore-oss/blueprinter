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
      return identifier_fields if view_name == :identifier

      @fields_for ||= Hash.new do |hash, key|
        fields = sortable_fields(key).values
        sorted_fields = sort_by_definition ? fields : fields.sort_by(&:name)
        hash[key] = identifier_fields + sorted_fields
      end

      @fields_for[view_name]
    end

    def transformers(view_name)
      views[view_name].transformers
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
      fields = merge_fields(fields, views[view_name].fields)
      views[view_name].included_view_names.each do |included_view_name|
        if view_name != included_view_name
          fields = merge_fields(fields, sortable_fields(included_view_name))
        end
      end

      views[view_name].excluded_field_names.each do |name|
        fields.delete(name)
      end

      fields
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
