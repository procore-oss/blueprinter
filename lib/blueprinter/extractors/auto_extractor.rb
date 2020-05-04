module Blueprinter
  # @api private
  class AutoExtractor < Extractor
    include EmptyTypes

    def initialize
      @hash_extractor = HashExtractor.new
      @public_send_extractor = PublicSendExtractor.new
      @block_extractor = BlockExtractor.new
      @datetime_formatter = DateTimeFormatter.new
      @delegate_extractor = DelegateExtractor.new
    end

    def extract(field_name, object, local_options, options = {})
      extraction = extractor(object, options).extract(field_name, object, local_options, options)
      value = @datetime_formatter.format(extraction, options)
      use_default_value?(value, options[:default_if]) ? default_value(options) : value
    end

    private

    def default_value(field_options)
      field_options.key?(:default) ? field_options.fetch(:default) : Blueprinter.configuration.field_default
    end

    def extractor(object, options)
      if options[:block]
        @block_extractor
      elsif options[:delegate]
        @delegate_extractor
      elsif object.is_a?(Hash)
        @hash_extractor
      else
        @public_send_extractor
      end
    end
  end
end
