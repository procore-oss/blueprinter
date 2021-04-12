module Blueprinter
  # @api private
  DefinitionPlaceholder = Struct.new :name, :view?
  class View
    attr_reader :excluded_field_names, :fields, :included_view_names, :name, :view_transformers, :definition_order, :cache_store_instance, :cache_store_options

    def initialize(name, fields: {}, included_view_names: [], excluded_view_names: [], transformers: [])
      @name = name
      @fields = fields
      @included_view_names = included_view_names
      @excluded_field_names = excluded_view_names
      @view_transformers = transformers
      @definition_order = []
      @sort_by_definition = Blueprinter.configuration.sort_fields_by.eql?(:definition)
      @cache_store_instance = nil
      @cache_store_options = {namespace: 'blueprinter'}
    end

    def transformers
      view_transformers.empty? ? Blueprinter.configuration.default_transformers : view_transformers
    end

    def track_definition_order(method, is_view = true)
      if @sort_by_definition
        @definition_order << DefinitionPlaceholder.new(method, is_view)
      end
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

      view.view_transformers.each do |transformer|
        add_transformer(transformer)
      end

      view.set_cache_store(cache_store_instance, cache_store_options)
    end

    def cache_key
      "#{name}/#{Digest::MD5.hexdigest(fields.to_s)}"
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
      track_definition_order(field.name,false)
      fields[field.name] = field
    end

    def set_cache_store(cache_store_instance, cache_store_options)
      @cache_store_instance = cache_store_instance
      @cache_store_options.merge!(cache_store_options)
    end
  end
end
