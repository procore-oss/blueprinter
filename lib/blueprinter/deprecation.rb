# @api private
module Blueprinter
  class Deprecation
    class << self
      VALID_BEHAVIORS = %i(silence stderror raise).freeze
      MESSAGE_PREFIX = "[DEPRECATION::WARNING] Blueprinter:".freeze

      def report(message)
        full_msg = qualififed_message(message)

        case behavior
        when :silence
          # Silence deprecation (noop)
        when :stderror
          warn qualififed_message(full_msg)
        when :raise
          raise BlueprinterError, full_msg
        end
      end

      private

      def qualififed_message(message)
        "#{MESSAGE_PREFIX} #{message}"
      end

      def behavior
        configured = Blueprinter.configuration.deprecation
        return configured unless !VALID_BEHAVIORS.include?(configured)

        :stderror
      end
    end
  end
end
