# frozen_string_literal: true

require 'blueprinter/extractor'

module Blueprinter
  # @api private
  class PublicSendExtractor < Extractor
    def extract(field_name, object, _local_options, _options = {})
      object.public_send(field_name)
    end
  end
end
