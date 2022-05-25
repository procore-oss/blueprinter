module Blueprinter
  # @api private
  class AutoExtractor < Extractor
    include EmptyTypes

    def initialize
      @hash_extractor = HashExtractor.new
      @public_send_extractor = PublicSendExtractor.new
      @block_extractor = BlockExtractor.new
      @datetime_formatter = DateTimeFormatter.new
    end

    def extract(field_name, object, local_options, options = {})
      value = extractor(object, options).extract(field_name, object, local_options, options)
      value = @datetime_formatter.format(value, options) if format_datetime?(options)
      use_default_value?(value, options[:default_if]) ? default_value(options) : value
    end

    private
    
    def format_datetime?(options)
      options.key?(:datetime_format) || Blueprinter.configuration.datetime_format
    end

    def default_value(field_options)
      field_options.key?(:default) ? field_options.fetch(:default) : Blueprinter.configuration.field_default
    end

    def extractor(object, options)
      if options[:block]
        @block_extractor
      elsif object.is_a?(Hash)
        @hash_extractor
      else
        @public_send_extractor
      end
    end
  end
end
