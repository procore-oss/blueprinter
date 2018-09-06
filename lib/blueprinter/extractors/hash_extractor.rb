module Blueprinter
  class HashExtractor < Extractor
    def extract(field_name, object_mapper, local_options, options = {})
      if object_mapper.respond_to?(field_name)
        object_mapper.public_send(field_name)
      else
        hash = object_mapper.to_h # conventional ruby protocol. Allows overriding by mapper
        hash[field_name] || hash[field_name.to_s]
      end
    end
  end
end
