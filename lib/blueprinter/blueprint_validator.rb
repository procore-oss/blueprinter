# frozen_string_literal: true

module Blueprinter
  # @api private
  class BlueprintValidator
    class << self
      # Determines whether the provided object is a valid Blueprint.
      #
      # @param blueprint [Object] The object to validate.
      # @return [Boolean] true if object is a valid Blueprint
      # @raise [Blueprinter::Errors::InvalidBlueprint] if the object is not a valid Blueprint.
      def validate!(blueprint)
        valid_blueprint?(blueprint) || raise(
          Errors::InvalidBlueprint,
          "#{blueprint} is not a valid blueprint. Please ensure it subclasses Blueprinter::Base or is a Proc."
        )
      end

      private

      def valid_blueprint?(blueprint)
        return false unless blueprint
        return true if blueprint.is_a?(Proc)
        return false unless blueprint.is_a?(Class)

        blueprint <= Blueprinter::Base
      end
    end
  end
end
