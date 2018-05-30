module Blueprinter
  class AutoExtractor < Extractor
    def extract(field_name, object, local_options, options = {})
      extractor = object.is_a?(Hash) ? HashExtractor : PublicSendExtractor
      extraction = extractor.extract(field_name, object, local_options, options)
      options.key?(:datetime_format) ? extraction.strftime(options[:datetime_format]) : extraction
    end
  end
end
