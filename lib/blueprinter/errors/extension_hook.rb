# frozen_string_literal: true

module Blueprinter
  module Errors
    class ExtensionHook < BlueprinterError
      def initialize(extension, hook, target, message)
        super("Extension hook error in #{hook} #{extension.class.name}##{target}: #{message}")
      end
    end
  end
end
