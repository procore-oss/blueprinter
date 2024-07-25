# frozen_string_literal: true

require 'blueprinter/extractor'

module Blueprinter
  # @api private
  class BlockExtractor < Extractor
    def extract(_field_name, object, local_options, options = {})
      options[:block].call(object, local_options)
    end
  end
end
