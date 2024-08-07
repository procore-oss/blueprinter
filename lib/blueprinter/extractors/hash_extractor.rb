# frozen_string_literal: true

require 'blueprinter/extractor'

module Blueprinter
  # @api private
  class HashExtractor < Extractor
    def extract(field_name, object, _local_options, _options = {})
      object[field_name]
    end
  end
end
