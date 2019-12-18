module Blueprinter
  include TypeHelpers

  EMPTY_COLLECTION = "empty_collection".freeze
  EMPTY_HASH = "empty_hash".freeze
  EMPTY_STRING = "empty_string".freeze

  # @api private
  module Nillables
    private
    def convert_to_nil?(value, nillable)
      return false unless nillable.present?

      case nillable
      when Blueprinter::EMPTY_COLLECTION
        array_like?(value) && value.empty?
      when Blueprinter::EMPTY_HASH
        value.is_a?(Hash) && value.empty?
      when Blueprinter::EMPTY_STRING
        value.to_s == ""
      else
        false
      end
    end
  end
end
