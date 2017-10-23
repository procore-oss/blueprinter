class Blueprinter::BlockSerializer < Blueprinter::Serializer
  def serialize(field_name, object, options = {})
    options[:block][field_name].call(object)
  end
end
