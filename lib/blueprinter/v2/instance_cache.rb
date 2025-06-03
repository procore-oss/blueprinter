# frozen_string_literal: true

module Blueprinter
  module V2
    #
    # A simple cache for instances of classes. Allows us to re-use Blueprint, Extension, and Serializer
    # instances during a given render.
    #
    class InstanceCache
      def initialize
        @cache = {}
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def [](obj, args = nil)
        case obj
        when Class
          if args&.any?
            @cache[[obj.object_id, args]] ||= obj.new(*args)
          else
            @cache[obj.object_id] ||= obj.new
          end
        when Proc
          @cache[obj.object_id] ||= obj.call
        else
          obj
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
