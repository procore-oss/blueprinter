module Blueprinter
  class AutoExtractor < Extractor
    def initialize
      @hash_extractor = HashExtractor.new
      @public_send_extractor = PublicSendExtractor.new
      @block_extractor = BlockExtractor.new
    end

    def extract(field_name, object, local_options, options = {})
      extraction = extractor(object, options).extract(field_name, object, local_options, options)
      options.key?(:datetime_format) ? format_datetime(extraction, options[:datetime_format]) : extraction
    end

    private

    def extractor(object, options)
      if options[:block]
        @block_extractor
      elsif object.is_a?(Hash)
        @hash_extractor
      else
        @public_send_extractor
      end
    end

    def format_datetime(datetime, format)
      return nil if datetime.nil?
      datetime.strftime(format)
    rescue NoMethodError
      raise BlueprinterError, 'Cannot format invalid DateTime object'
    end
  end
end
