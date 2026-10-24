# frozen_string_literal: true

require 'blueprinter/extractor'
require 'blueprinter/empty_types'
require 'blueprinter/extractors/block_extractor'
require 'blueprinter/extractors/hash_extractor'
require 'blueprinter/extractors/public_send_extractor'
require 'blueprinter/formatters/date_time_formatter'

module Blueprinter
  class AutoExtractor < Extractor
    include EmptyTypes

    def initialize
      @hash_extractor = HashExtractor.new
      @public_send_extractor = PublicSendExtractor.new
      @block_extractor = BlockExtractor.new
      @datetime_formatter = DateTimeFormatter.new
    end

    def extract(field_name, object, local_options, options = {})
      extraction = extractor(object, options).extract(field_name, object, local_options, options)
      # DateTimeFormatter asks every value to respond_to?(:strftime). Skip that unless a format is configured.
      # A global format is read each extract, so a format set after the first render still applies.
      global_format = Blueprinter.configuration.datetime_format
      value = if options[:datetime_format] || !global_format.nil?
                @datetime_formatter.format(extraction, options)
              else
                extraction
              end
      use_default_value?(value, options[:default_if]) ? default_value(options) : value
    end

    private

    def default_value(field_options)
      field_options.key?(:default) ? field_options.fetch(:default) : Blueprinter.configuration.field_default
    end

    # Subclasses override this to dispatch to their own extractors (README "Configurable Extractors").
    #
    # @api public
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
