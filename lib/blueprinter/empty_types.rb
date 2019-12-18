module Blueprinter
  include TypeHelpers
  InvalidEmptyTypeError = Class.new(BlueprinterError)

  EMPTY_COLLECTION = "empty_collection".freeze
  EMPTY_HASH = "empty_hash".freeze
  EMPTY_STRING = "empty_string".freeze
  NIL_VALUE = "nil_value".freeze

  module EmptyTypeHelper
    private

    def use_default_value?(value, empty_type = NIL_VALUE)
      case empty_type
      when Blueprinter::NIL_VALUE
        value.nil?
      when Blueprinter::EMPTY_COLLECTION
        array_like?(value) && value.empty?
      when Blueprinter::EMPTY_HASH
        value.is_a?(Hash) && value.empty?
      when Blueprinter::EMPTY_STRING
        value.to_s == ""
      else
        raise InvalidEmptyTypeError, 'Invalid empty type: #{empty_type} provided.'
      end
    end
  end
end
