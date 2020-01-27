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

      fields_hash = sortable_fields(view_name)
      sorted_fields = sort_by_definition ? sort_by_def(view_name, fields_hash) : fields_hash.values.sort_by(&:name)
      identifier_fields + sorted_fields
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

    def sort_by_def(view_name, fields)
      result = views[:default].definition_order.reduce({}) do |memo, key|
        if key.is_a?(Hash)
          reduce_helper(memo, key, fields) if view_name == key.keys.first # recur all the way down on the given view_name but no others!
        else
          memo[key] = fields[key]
        end
        memo
      end
      result.values
    end

    def reduce_helper(memo, key, fields)
      # recur for all included views
      if key.is_a?(Hash)
        reduce_helper(memo,views[key.keys.first].definition_order,fields)
      elsif key.is_a?(Array)
        key.each {|x| reduce_helper(memo, x, fields)  }
      else
        memo[key] = fields[key]
      end
      memo
    end

    def merge_fields(source_fields, included_fields)
      source_fields.merge! included_fields
    end
  end
end
