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

      fields, excluded_fields = sortable_fields(view_name)
      sorted_fields = sort_by_definition ? sort_by_def(view_name, fields) : fields.values.sort_by(&:name)

      (identifier_fields + sorted_fields).reject { |field| excluded_fields.include?(field.name) }
    end

    def cache_key(view_name)
      fields_cache_keys = fields_for(view_name).map(&:cache_key)
      Digest::MD5.hexdigest(fields_cache_keys.to_s)
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

    # @param [String] view_name
    # @return [Array<(Hash, Hash<String, NilClass>)>] fields, excluded_fields
    def sortable_fields(view_name)
      excluded_fields = {}
      fields = views[:default].fields
      views[view_name].included_view_names.each do |included_view_name|
        next if view_name == included_view_name

        view_fields, view_excluded_fields = sortable_fields(included_view_name)
        fields = merge_fields(fields, view_fields)
        excluded_fields.merge!(view_excluded_fields)
      end
      fields = merge_fields(fields, views[view_name].fields)

      views[view_name].excluded_field_names.each { |name| excluded_fields[name] = nil }

      [fields, excluded_fields]
    end

    # select and order members of fields according to traversal of the definition_orders
    def sort_by_def(view_name, fields)
      ordered_fields = {}
      views[:default].definition_order.each { |definition| add_to_ordered_fields(ordered_fields, definition, fields, view_name)  }
      ordered_fields.values
    end

    # view_name_filter allows to follow definition order all the way down starting from the view_name given to sort_by_def()
    # but include no others at the top-level
    def add_to_ordered_fields(ordered_fields, definition, fields, view_name_filter = nil)
      if definition.view?
        if view_name_filter.nil? || view_name_filter == definition.name
          views[definition.name].definition_order.each { |_definition| add_to_ordered_fields(ordered_fields, _definition, fields) }
        end
      else
        ordered_fields[definition.name] = fields[definition.name]
      end
    end

    def merge_fields(source_fields, included_fields)
      source_fields.merge included_fields
    end
  end
end
