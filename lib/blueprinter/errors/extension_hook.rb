# frozen_string_literal: true

module Blueprinter
  module Errors
    class ExtensionHook < StandardError
      attr_reader :message

      def initialize(extension, hook, message)
        @message = "Extension hook error in #{extension.class.name}##{hook}: #{message}"
      end
    end
  end
end
