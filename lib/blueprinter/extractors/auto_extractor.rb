module Blueprinter
  class AutoExtractor < Extractor
    def initialize
      @hash_extractor = HashExtractor.new
      @public_send_extractor = PublicSendExtractor.new
    end

    def extract(field_name, object, local_options, options = {})
      extractor = object.is_a?(Hash) ? @hash_extractor : @public_send_extractor
      extraction = extractor.extract(field_name, object, local_options, options)
      options.key?(:datetime_format) ? format_datetime(extraction, options[:datetime_format]) : extraction
    end

    private

    def format_datetime(datetime, format)
      datetime.strftime(format)
    rescue NoMethodError
      raise BlueprinterError, 'Cannot format invalid DateTime object'
    end
  end
end
