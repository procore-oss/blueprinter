module Blueprinter
  class AMSExtractor < Extractor
    def extract(association_name, object, local_options, options={})
      ActiveModelSerializers::SerializableResource.new(object.public_send(association_name)).as_json
    end
  end
end
