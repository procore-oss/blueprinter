class Blueprinter::LocalMethodSerializer < Blueprinter::Serializer
  def serialize(field_name, _object, options = {})
    options[:local_methods][field_name]
  end
end
