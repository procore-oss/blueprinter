class PaintedRabbit::PublicSendSerializer < PaintedRabbit::Serializer
  def serialize(field_name, object, options = {})
    object.public_send(field_name)
  end
end
