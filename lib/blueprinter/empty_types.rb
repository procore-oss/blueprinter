require_relative 'helpers/type_helpers'

module Blueprinter
  EMPTY_COLLECTION = "empty_collection".freeze
  EMPTY_HASH = "empty_hash".freeze
  EMPTY_STRING = "empty_string".freeze

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
        value.to_s == ""
      else
        raise BlueprinterError, "Invalid empty type '#{empty_type}' received. Must be one of [nil, Blueprinter::EMPTY_COLLECTION, Blueprinter::EMPTY_HASH, Blueprinter::EMPTY_STRING]"
      end
    end
  end
end
