# frozen_string_literal: true

require 'blueprinter/helpers/type_helpers'

module Blueprinter
  EMPTY_COLLECTION = 'empty_collection'
  EMPTY_HASH = 'empty_hash'
  EMPTY_STRING = 'empty_string'

  module EmptyTypes
    include TypeHelpers

    private

    def use_default_value?(value, empty_type)
      return value.nil? unless empty_type

      case empty_type
      when Blueprinter::EMPTY_COLLECTION
        array_like?(value) && value.empty?
      when Blueprinter::EMPTY_HASH
        value.is_a?(Hash) && value.empty?
      when Blueprinter::EMPTY_STRING
        value.to_s == ''
      end
    end
  end
end
