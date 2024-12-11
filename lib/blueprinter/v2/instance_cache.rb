# frozen_string_literal: true

module Blueprinter
  module V2
    class InstanceCache
      def initialize
        @cache = {}
      end

      def [](obj)
        if obj.is_a? Class
          @cache[obj.object_id] ||= obj.new
        else
          obj
        end
      end
    end
  end
end
