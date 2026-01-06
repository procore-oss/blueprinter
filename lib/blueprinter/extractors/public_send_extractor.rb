# frozen_string_literal: true

require 'blueprinter/extractor'

module Blueprinter
  # @api private
  class PublicSendExtractor < Extractor
    # @param field_name [Symbol] The name of the field to extract
    # @param object [Object] The object in which the field_name is sent to for extraction
    def extract(field_name, object, _local_options, _options = {})
      object.public_send(field_name)
    end
  end
end
