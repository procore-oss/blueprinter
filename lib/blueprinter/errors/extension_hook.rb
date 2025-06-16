# frozen_string_literal: true

module Blueprinter
  module Errors
    class ExtensionHook < StandardError
      attr_reader :extension, :hook, :message

      def initialize(extension, hook, message)
        @extension = extension
        @hook = hook
        @message = message
      end
    end
  end
end
