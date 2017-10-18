class Blueprinter::AssociationSerializer < Blueprinter::Serializer
  def serialize(association_name, object, options={})
    if options[:blueprint]
      view = options[:view] || :default
      options[:blueprint].prepare(object.public_send(association_name), view: view)
    else
      object.public_send(association_name)
    end
  end
end
