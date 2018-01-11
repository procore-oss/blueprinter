module Blueprinter
  class AutoSerializer < Blueprinter::Serializer
    def serialize(field_name, object, local_options, options = {})
      serializer = object.is_a?(Hash) ? HashSerializer : PublicSendSerializer
      serializer.serialize(field_name, object, local_options, options = {})
    end
  end
end
