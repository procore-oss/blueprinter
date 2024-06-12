# frozen_string_literal: true

module Blueprinter
  # @api private
  DefinitionPlaceholder = Struct.new :name, :view?
  class View
    attr_reader :excluded_field_names, :fields, :included_view_names, :name, :view_transformers, :definition_order

    def initialize(name, local_options: {}, fields: {}, included_view_names: [], excluded_view_names: [], transformers: [])
      @name = name
      @fields = fields
      @included_view_names = included_view_names
      @excluded_field_names = excluded_view_names
      @view_transformers = transformers
      @definition_order = []
      @sort_by_definition = Blueprinter.configuration.sort_fields_by.eql?(:definition)
      @if_callable = local_options[:if]
    end

    def finalize
      return unless @if_callable

      @fields.each_value do |field|
        field.add_if(@if_callable)
      end
    end

    def track_definition_order(method, viewable: true)
      return unless @sort_by_definition

      @definition_order << DefinitionPlaceholder.new(method, viewable)
    end

    def inherit(parent)
      parent.fields.each_value do |field|
        self << field.clone
      end

      parent.included_view_names.each do |view_name|
        include_view(view_name)
      end

      parent.excluded_field_names.each do |field_name|
        exclude_field(field_name)
      end

      parent.view_transformers.each do |transformer|
        add_transformer(transformer)
      end
    end

    def include_view(view_name)
      track_definition_order(view_name)
      included_view_names << view_name
    end

    def include_views(view_names)
      view_names.each do |view_name|
        track_definition_order(view_name)
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
      view_transformers << custom_transformer
    end

    def <<(field)
      track_definition_order(field.name, viewable: false)
      fields[field.name] = field
    end
  end
end
