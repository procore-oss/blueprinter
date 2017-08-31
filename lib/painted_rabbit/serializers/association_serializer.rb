class PaintedRabbit::AssociationSerializer < PaintedRabbit::Serializer
  serialize do |association_name, object, options={}|
    if options[:serializer]
      view = options[:view] || :default
      options[:serializer].hashify(object.public_send(association_name), view: view)
    else
      object.public_send(association_name)
    end
  end
end
