module Blueprinter
  class AutoExtractor < Extractor
    def extract(field_name, object, local_options, options = {})
      extractor = object.is_a?(Hash) ? HashExtractor : PublicSendExtractor
      extractor.extract(field_name, object, local_options, options)
    end
  end
end
