module Blueprinter
  class DateTimeExtractor < Extractor
    def extract(field_name, object, local_options, options = {})
      datetime = object.public_send(field_name)
      datetime.strftime(options[:datetime_format])
    end
  end
end
