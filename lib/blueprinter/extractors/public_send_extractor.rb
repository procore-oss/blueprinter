module Blueprinter
  class PublicSendExtractor < Extractor
    def extract(field_name, object_mapper, local_options, options = {})
      object_mapper.public_send(field_name)
    end
  end
end
