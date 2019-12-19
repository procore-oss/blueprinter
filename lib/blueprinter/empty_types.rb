require_relative 'helpers/type_helpers'

module Blueprinter
  EMPTY_COLLECTION = "empty_collection".freeze
  EMPTY_HASH = "empty_hash".freeze
  EMPTY_STRING = "empty_string".freeze

  module EmptyTypes
    include TypeHelpers
    private

    def use_default_value?(value, empty_type)
      case empty_type
      when Blueprinter::EMPTY_COLLECTION
        array_like?(value) && value.empty?
      when Blueprinter::EMPTY_HASH
        value.is_a?(Hash) && value.empty?
      when Blueprinter::EMPTY_STRING
        value.to_s == ""
      else
        value.nil?
      end
    end
  end
end
