class Blueprinter::AssociationSerializer < Blueprinter::Serializer
  def serialize(association_name, object, local_options, options={})
    value = object.public_send(association_name)
    return value if value.nil?
    view = options[:view] || :default
    options[:blueprint].prepare(value, view_name: view, local_options: local_options)
  end
end
