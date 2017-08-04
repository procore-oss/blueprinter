class PaintedRabbit::AssociationSerializer < PaintedRabbit::Serializer
  serialize do |association_name, object, options|
    if object.class.respond_to? :serializer
      object.class.serializer.render(object.public_send(association_name), options)
    else
      object.public_send(association_name)
    end
  end
end
