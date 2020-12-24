# frozen_string_literal: true

# @api private
module Blueprinter
  class Deprecation
    class << self
      VALID_BEHAVIORS = %i(silence stderror raise).freeze
      MESSAGE_PREFIX = "[DEPRECATION::WARNING] Blueprinter:"

      def report(message)
        full_msg = qualified_message(message)

        case behavior
        when :silence
          # Silence deprecation (noop)
        when :stderror
          warn full_msg
        when :raise
          raise BlueprinterError, full_msg
        end
      end

      private

      def qualified_message(message)
        "#{MESSAGE_PREFIX} #{message}"
      end

      def behavior
        configured = Blueprinter.configuration.deprecations
        return configured unless !VALID_BEHAVIORS.include?(configured)

        :stderror
      end
    end
  end
end
