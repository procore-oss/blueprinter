module Blueprinter
  class AutoExtractor < Extractor
    def extract(field_name, object, local_options, options = {})
      extractor =
        if object.is_a?(Hash)
          HashExtractor
        elsif options.key?(:datetime_format)
          DateTimeExtractor
        else
          PublicSendExtractor
        end
      extractor.extract(field_name, object, local_options, options)
    end
  end
end
