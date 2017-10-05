class Blueprinter::Serializer
  def initialize
  end

  def serialize(field_name, object, options={})
    fail NotImplementedError, "A serializer must implement #serialize"
  end

  def self.serialize(field_name, object, options={})
    self.new.serialize(field_name, object, options)
  end
end
