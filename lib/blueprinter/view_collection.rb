# frozen_string_literal: true

require 'blueprinter/view'

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

    def view?(view_name)
      views.key? view_name
    end

    def fields_for(view_name)
      return identifier_fields if view_name == :identifier

      fields, excluded_fields = sortable_fields(view_name)
      sorted_fields = sort_by_definition ? sort_by_def(view_name, fields) : fields.values.sort_by(&:name)

      (identifier_fields + sorted_fields).tap do |fields_array|
        fields_array.reject! { |field| excluded_fields.include?(field.name) }
      end
    end

    def transformers(view_name)
      included_transformers = gather_transformers_from_included_views(view_name).reverse
      all_transformers = [*views[:default].view_transformers, *included_transformers].uniq
      all_transformers.empty? ? Blueprinter.configuration.default_transformers : all_transformers
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
      fields = views[:default].fields.clone
      views[view_name].included_view_names.each do |included_view_name|
        next if view_name == included_view_name

        view_fields, view_excluded_fields = sortable_fields(included_view_name)
        fields.merge!(view_fields)
        excluded_fields.merge!(view_excluded_fields)
      end
      fields.merge!(views[view_name].fields) unless view_name == :default

      views[view_name].excluded_field_names.each { |name| excluded_fields[name] = nil }

      [fields, excluded_fields]
    end

    # select and order members of fields according to traversal of the definition_orders
    def sort_by_def(view_name, fields)
      ordered_fields = {}
      views[:default].definition_order.each do |definition|
        add_to_ordered_fields(ordered_fields, definition, fields, view_name)
      end
      ordered_fields.values
    end

    # view_name_filter allows to follow definition order all the way down starting from the view_name given to sort_by_def()
    # but include no others at the top-level
    def add_to_ordered_fields(ordered_fields, definition, fields, view_name_filter = nil)
      if definition.view?
        if view_name_filter.nil? || view_name_filter == definition.name
          views[definition.name].definition_order.each do |defined|
            add_to_ordered_fields(ordered_fields, defined, fields)
          end
        end
      else
        ordered_fields[definition.name] = fields[definition.name]
      end
    end

    def gather_transformers_from_included_views(view_name)
      current_view = views[view_name]
      already_included_transformers = current_view.included_view_names.flat_map do |included_view_name|
        next [] if view_name == included_view_name

        gather_transformers_from_included_views(included_view_name)
      end
      [*already_included_transformers, *current_view.view_transformers].uniq
    end
  end
end
