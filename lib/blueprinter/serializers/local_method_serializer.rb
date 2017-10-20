class Blueprinter::LocalMethodSerializer < Blueprinter::Serializer
  def serialize(field_name, object, options = {})
    options[:local_methods][field_name].call(object)
  end
end
