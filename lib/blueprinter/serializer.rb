# @api private
class Blueprinter::Serializer
  def initialize
  end

  def serialize(field_name, object, local_options, options={})
    fail NotImplementedError, "A serializer must implement #serialize"
  end

  def self.serialize(field_name, object, local_options, options={})
    self.new.serialize(field_name, object, local_options, options)
  end
end
