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

  class Field
    attr_reader :method, :name, :serializer
    def initialize(method, name, serializer)
      @method = method
      @name = name
      @serializer = serializer
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

    def self.association(method, name: method, serializer: PublicSendSerializer) # TODO: options
      current_views.each do |view_name|
        views[view_name] ||= {}
        views[view_name][name] = Field.new(method, name, serializer.bleh)
      end
    end

    def self.render(object, view: :default)
      if object.respond_to? :each
        object.map do |obj|
          render_fields = if view == :default
                            views[:identifier].values + views[:default].values.sort_by(&:name)
                          else
                            views[:identifier].values + 
                              (views[:default].values + views[view].values).
                                sort_by(&:name)
                          end
          render_fields.each_with_object({}) { |field, hash|
            hash[field.name] = field.serializer.call(field.method, obj)
          }
        end.to_json
      else
        views[view].values.each_with_object({}) { |field, hash|
          hash[field.name] = field.serializer.call(field.method, object)
        }.to_json
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
