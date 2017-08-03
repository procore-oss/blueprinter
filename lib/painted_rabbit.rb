module PaintedRabbit
  class Serializer
    def initialize(block)
      @block = block
    end
    def self.serialize(&block)
      @_blah = self.new(block)
    end

    def self.bleh
      @_blah
    end

    def call(field_name, object)
      @block.call(field_name, object)
    end
  end

  class PublicSendSerializer < Serializer
    serialize do |field_name, object|
      object.public_send(field_name)
    end
  end

  class AssociationSerializer < Serializer
    serialize do |association_name, object, options|
      if object.class.respond_to? :serializer
        object.class.serializer.render(object.public_send(association_name), options)
      else
        object.public_send(association_name)
      end
    end
  end

  class Field
    attr_reader :method, :name, :serializer, :options
    def initialize(method, name, serializer, options = {})
      @method = method
      @name = name
      @serializer = serializer
      @options = options
    end
  end

  class Base
    def self.identifier(method, name: method, serializer: PublicSendSerializer)
      views[:identifier] = { name: Field.new(method, name, serializer.bleh) }
    end

    def self.field(method, name: method, serializer: PublicSendSerializer) # TODO: options
      current_views.each do |view_name|
        views[view_name] ||= {}
        views[view_name][name] = Field.new(method, name, serializer.bleh)
      end
    end

    def self.association(method, name: method, serializer: AssociationSerializer)
      current_views.each do |view_name|
        views[view_name] ||= {}
        views[view_name][name] = Field.new(method,
                                           name,
                                           serializer.bleh,
                                           association: true)
      end
    end

    def self.render(object, view: :default)
      if object.respond_to? :each
        if object.respond_to? :select # TODO: Change to more explicitely test for AR
          select_columns = (active_record_attributes(object) &
            render_fields(view).map(&:method)) +
            required_lookup_attributes(object)
          object = object.select(*select_columns)
        end
        object = include_associations(object, view: view)
        object.map do |obj|
          render_fields(view).each_with_object({}) { |field, hash|
            hash[field.name] = field.serializer.call(field.method, obj)#, field.options)
          }
        end.to_json
      else
        views[view].values.each_with_object({}) { |field, hash|
          hash[field.name] = field.serializer.call(field.method, object, field.options)
        }.to_json
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
      if view == :default
        views[:identifier].values + views[:default].values.sort_by(&:name)
      else
        (views[:identifier].values +
          views[:default].values + views[view].values).
            sort_by(&:name)
      end
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

    # I had to test this, so a note for later, class level instance variables
    # are not mutated at the parent class level when they are changed at the
    # inherited class
    def self.tracked_fields
      @tracked_fields ||= []
    end

    #def self.current_views=(view_list)
    #  @current_views = Array(view_list)
    #end

    def self.current_views
      @current_views ||= [:default]
    end

    def self.views
      @views ||= { identifier: {}, default: {} }
    end
  end
end
