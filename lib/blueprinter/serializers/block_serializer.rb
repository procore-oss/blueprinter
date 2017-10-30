class Blueprinter::BlockSerializer < Blueprinter::Serializer
  def serialize(field_name, object, local_options, options = {})
    options[:block][field_name].call(object, local_options)
  end
end
