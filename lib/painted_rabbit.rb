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

    def call(attribute_name, object)
      @block.call(attribute_name, object)
    end
  end

  class PublicSendSerializer < Serializer
    serialize do |attribute_name, object|
      object.public_send(attribute_name)
    end
  end

  class Attribute
    attr_reader :method, :name, :serializer
    def initialize(method, name, serializer)
      @method = method
      @name = name
      @serializer = serializer
    end
  end

  class Base
    def self.attribute(method, name: method, serializer: PublicSendSerializer) # TODO: options
      attributes << Attribute.new(method, name, serializer.bleh)
    end

    def self.render(object)
      attributes.each_with_object({}) { |attribute, hash|
        hash[attribute.name] = attribute.serializer.call(attribute.method, object)
        # hash[attribute.name] = object.public_send(attribute.method)
      }.to_json
    end

    # I had to test this, so a note for later, class level instance variables
    # are not mutated at the parent class level when they are changed at the
    # inherited class
    def self.attributes
      @attributes ||= []
    end
  end
end
