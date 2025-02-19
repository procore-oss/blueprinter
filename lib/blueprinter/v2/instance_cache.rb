# frozen_string_literal: true

module Blueprinter
  module V2
    #
    # A simple cache for instances of classes. Allows us to re-use Blueprint and Extension instances during a given render.
    #
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
