require 'json'
require_relative 'painted_rabbit_error'
require_relative 'field'
require_relative 'serializer'
require_relative 'view'
require_relative 'view_collection'
require_relative 'serializers/association_serializer'
require_relative 'serializers/public_send_serializer'

module PaintedRabbit
  class Base
    def self.identifier(method, name: method, serializer: PublicSendSerializer)
      views[:identifier] << Field.new(method, name, serializer)
    end

    def self.field(method, options = {})
      name = options.delete(:name) || method
      serializer = options.delete(:serializer) || AssociationSerializer
      current_view << Field.new(method, name, serializer, options)
    end

    # Options:
    #   preload: Set to false to stop trying to eagerly load associations
    def self.association(method, options = {})
      name = options.delete(:name) || method
      current_view << Field.new(method,
                                       name,
                                       AssociationSerializer,
                                       options.merge(association: true))
    end

    def self.render(object, view: :default)
      jsonify(prepare(object, view: view))
    end

    # This is the magic method that converts complex objects into a simple hash
    # ready for JSON conversion
    def self.prepare(object, view:)
      unless views.has_view? view
        raise PaintedRabbitError, "View '#{view}' is not defined"
      end
      prepared_object = select_columns(object, view: view)
      prepared_object = include_associations(prepared_object, view: view)
      if prepared_object.respond_to? :map
        prepared_object.map do |obj|
          object_to_hash(obj, view: view)
        end
      else
        object_to_hash(prepared_object, view: view)
      end
    end

    def self.fields(*field_names)
      field_names.each do |field_name|
        current_view << Field.new(field_name, field_name, PublicSendSerializer)
      end
    end

    def self.associations(view = :default)
      views.fields_for(view).select { |f| f.options[:association] }
    end

    def self.include_view(view)
      current_view.included_views << view
    end

    def self.exclude(field_name)
      current_view.excluded_fields << field_name
    end

    def self.view(view_name)
      @current_view = views[view_name]
      yield
      @current_view = views[:default]
    end

    private

    def self.object_to_hash(object, view:)
      views.fields_for(view).each_with_object({}) do |field, hash|
        hash[field.name] = field.serializer.serialize(field.method, object, field.options)
      end
    end
    private_class_method :object_to_hash

    def self.select_columns(object, view:)
      unless defined?(ActiveRecord::Base) &&
          object.is_a?(ActiveRecord::Base) &&
          object.respond_to?(:klass)
        return object
      end
      select_columns = (active_record_attributes(object) &
        views.fields_for(view).map(&:method)) +
        required_lookup_attributes(object)
      object.select(*select_columns)
    end
    private_class_method :select_columns

    def self.include_associations(object, view:)
      unless defined?(ActiveRecord::Base) &&
          object.is_a?(ActiveRecord::Base) &&
          object.respond_to?(:klass)
        return object
      end
      # TODO: Do we need to support more than `eager_load` ?
      fields_to_include = associations(view).select { |a|
        a.options[:include] != false
      }.map(&:method)
      if !fields_to_include.empty?
        object.eager_load(*fields_to_include)
      else
        object
      end
    end
    private_class_method :include_associations

    def self.active_record_attributes(object)
      object.klass.column_names.map(&:to_sym)
    end
    private_class_method :active_record_attributes

    # Find all the attributes required for includes & eager/pre-loading
    def self.required_lookup_attributes(object)
      # TODO: We may not need all four of these
      lookup_values = (object.includes_values +
        object.preload_values +
        object.joins_values +
        object.eager_load_values).uniq
      lookup_values.map do |value|
        object.reflections[value.to_s].foreign_key
      end
    end
    private_class_method :required_lookup_attributes

    def self.jsonify(blob)
      if blob.respond_to? :to_json
        blob.to_json
      else
        JSON.generate(blob)
      end
    end
    private_class_method :jsonify

    def self.current_view
      @current_view ||= views[:default]
    end
    private_class_method :current_view

    def self.views
      @views ||= ViewCollection.new
    end
    private_class_method :views
  end
end
