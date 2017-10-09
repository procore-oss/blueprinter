require 'json'
require_relative 'blueprinter_error'
require_relative 'field'
require_relative 'serializer'
require_relative 'view'
require_relative 'view_collection'
require_relative 'optimizer'
require_relative 'serializers/association_serializer'
require_relative 'serializers/public_send_serializer'

module Blueprinter
  class Base
    def self.identifier(method, name: method, serializer: PublicSendSerializer)
      view_collection[:identifier] << Field.new(method, name, serializer)
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
    # Note: we accept view (public interface) that is in reality a view_name,
    #   so we rename it for clarity
    def self.prepare(object, view:)
      view_name = view
      unless view_collection.has_view? view_name
        raise BlueprinterError, "View '#{view_name}' is not defined"
      end
      fields = view_collection.fields_for(view)
      prepared_object = Optimizer.optimize!(object, fields: fields)
      prepared_object = include_associations(prepared_object, view_name: view_name)
      if prepared_object.respond_to? :map
        prepared_object.map do |obj|
          object_to_hash(obj, view_name: view_name)
        end
      else
        object_to_hash(prepared_object, view_name: view_name)
      end
    end

    def self.fields(*field_names)
      field_names.each do |field_name|
        current_view << Field.new(field_name, field_name, PublicSendSerializer)
      end
    end

    def self.associations(view_name = :default)
      view_collection.fields_for(view_name).select { |f| f.options[:association] }
    end

    def self.include_view(view_name)
      current_view.include_view(view_name)
    end

    def self.exclude(field_name)
      current_view.exclude_field(field_name)
    end

    def self.view(view_name)
      @current_view = view_collection[view_name]
      yield
      @current_view = view_collection[:default]
    end

    private

    def self.object_to_hash(object, view_name:)
      view_collection.fields_for(view_name).each_with_object({}) do |field, hash|
        hash[field.name] = field.serializer.serialize(field.method, object, field.options)
      end
    end
    private_class_method :object_to_hash

    def self.include_associations(object, view_name:)
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

    def self.jsonify(blob)
      if blob.respond_to? :to_json
        blob.to_json
      else
        JSON.generate(blob)
      end
    end
    private_class_method :jsonify

    def self.current_view
      @current_view ||= view_collection[:default]
    end
    private_class_method :current_view

    def self.view_collection
      @view_collection ||= ViewCollection.new
    end
    private_class_method :view_collection
  end
end
