# frozen_string_literal: true

module Blueprinter
  module V2
    class Extension
      class << self
        attr_accessor :formatters
      end

      def self.inherited(ext)
        ext.formatters = {}
      end

      def self.format(klass, helper = nil, &action)
        formatters[klass] = helper || action
      end
    end
  end
end
