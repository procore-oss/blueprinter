# frozen_string_literal: true

module Blueprinter
  module Errors
    class ExtensionHook < StandardError
      attr_reader :message

      def initialize(extension, hook, target, message)
        @message = "Extension hook error in #{hook} #{extension.class.name}##{target}: #{message}"
      end
    end
  end
end
