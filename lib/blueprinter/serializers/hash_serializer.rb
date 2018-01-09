class Blueprinter::HashSerializer < Blueprinter::Serializer
  def serialize(field_name, object, local_options, options = {})
    object[field_name] || object[field_name.to_s]
  end
end
