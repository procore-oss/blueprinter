require 'json'
require_relative 'painted_rabbit_error'
require_relative 'field'
require_relative 'serializer'
require_relative 'serializers/association_serializer'
require_relative 'serializers/public_send_serializer'

module PaintedRabbit
  class Base
    def self.identifier(method, name: method, serializer: PublicSendSerializer)
      views[:identifier] = { name: Field.new(method, name, serializer.bleh) }
    end

    def self.field(method, options = {})
      name = options.delete(:name) || method
      serializer = options.delete(:serializer) || AssociationSerializer
      current_views.each do |view_name|
        views[view_name] ||= {}
        views[view_name][name] = Field.new(method, name, serializer.bleh, options)
      end
    end

    # Options:
    #   preload: Set to false to stop trying to eagerly load associations
    def self.association(method, options = {})
      name = options.delete(:name) || method
      current_views.each do |view_name|
        views[view_name] ||= {}
        views[view_name][name] = Field.new(method,
                                           name,
                                           AssociationSerializer.bleh,
                                           options.merge(association: true))
      end
    end

    def self.render(object, view: :default)
      jsonify(hashify(object, view: view))
    end

    def self.hashify(object, view:)
      unless views.keys.include? view
        raise PaintedRabbitError, "View '#{view}' is not defined"
      end
      output_hash = if object.respond_to? :each
        if object.respond_to? :select # TODO: Change to more explicitely test for AR
          select_columns = (active_record_attributes(object) &
            render_fields(view).map(&:method)) +
            required_lookup_attributes(object)
          object = object.select(*select_columns)
        end
        object = include_associations(object, view: view)
        object.map do |obj|
          render_fields(view).each_with_object({}) { |field, hash|
            hash[field.name] = field.serializer.call(field.method, obj, field.options)
          }
        end
      else
        render_fields(view).each_with_object({}) { |field, hash|
          hash[field.name] = field.serializer.call(field.method, object, field.options)
        }
      end
    end

    def self.include_associations(object, view:)
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

    def self.active_record_attributes(object)
      object.klass.column_names.map(&:to_sym)
    end

    def self.render_fields(view)
      views[:identifier].values +
        views[:default].merge(views[view]).values.sort_by(&:name)
    end

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

    def self.fields(*field_names)
      field_names.each do |field_name|
        current_views.each do |view_name|
          views[view_name] ||= {}
          views[view_name][field_name] = Field.new(field_name, field_name, PublicSendSerializer.bleh)
        end
      end
    end

    def self.associations(view = :default)
      render_fields(view).select { |f| f.options[:association] }
    end

    def self.include_in(view_list)
      @current_views = Array(view_list)
      yield
      current_views = [:default]
    end

    private

    def self.jsonify(blob)
      if blob.respond_to? :to_json
        blob.to_json
      else
        JSON.generate(blob)
      end
    end

    # I had to test this, so a note for later, class level instance variables
    # are not mutated at the parent class level when they are changed at the
    # inherited class
    def self.tracked_fields
      @tracked_fields ||= []
    end

    def self.current_views
      @current_views ||= [:default]
    end

    def self.views
      @views ||= { identifier: {}, default: {} }
    end
  end
end
