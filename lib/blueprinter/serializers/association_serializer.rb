class Blueprinter::AssociationSerializer < Blueprinter::Serializer
  def serialize(association_name, object, local_options, options={})
    if options[:blueprint]
      view = options[:view] || :default
      options[:blueprint].prepare(object.public_send(association_name), view_name: view, local_options: local_options)
    else
      object.public_send(association_name)
    end
  end
end
