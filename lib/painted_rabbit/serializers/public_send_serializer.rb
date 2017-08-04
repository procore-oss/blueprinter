class PaintedRabbit::PublicSendSerializer < PaintedRabbit::Serializer
  serialize do |field_name, object|
    object.public_send(field_name)
  end
end
