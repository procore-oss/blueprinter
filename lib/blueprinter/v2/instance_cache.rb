# frozen_string_literal: true

module Blueprinter
  module V2
    class InstanceCache
      def initialize
        @cache = {}
      end

      def [](klass)
        @cache[klass] ||= klass.new
      end
    end
  end
end
