class Blueprinter::PublicSendSerializer < Blueprinter::Serializer
  def serialize(field_name, object, local_options, options = {})
    object.public_send(field_name)
  end
end
