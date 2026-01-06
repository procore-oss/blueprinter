# frozen_string_literal: true

require 'blueprinter/extractor'

module Blueprinter
  # @api private
  class HashExtractor < Extractor
    # @param field_name [Symbol] The name of the field to extract
    # @param object [Hash] The Hash object in which the field_name is extracted from
    def extract(field_name, object, _local_options, _options = {})
      object[field_name]
    end
  end
end
