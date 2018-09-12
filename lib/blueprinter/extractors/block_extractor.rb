module Blueprinter
  class BlockExtractor < Extractor
    def extract(field_name, object_mapper, local_options, options = {})
      options[:block][field_name].call(object_mapper, local_options)
    end
  end
end
