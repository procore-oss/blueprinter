class Blueprinter::AssociationSerializer < Blueprinter::Serializer
  def serialize(association_name, object, options={})
    if options[:serializer]
      view = options[:view] || :default
      options[:serializer].prepare(object.public_send(association_name), view: view)
    else
      object.public_send(association_name)
    end
  end
end
