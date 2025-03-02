# frozen_string_literal: true

require 'blueprinter/extractor'

module Blueprinter
  # @api private
  class BlockExtractor < Extractor
    # @param object [Object] The object in which the block is called with
    # @param local_options [Hash] The local options to pass to the block
    def extract(_field_name, object, local_options = {}, options = {})
      options[:block].call(object, local_options)
    end
  end
end
