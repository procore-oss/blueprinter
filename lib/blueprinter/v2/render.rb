# frozen_string_literal: true

require 'blueprinter/v2/instance_cache'

module Blueprinter
  module V2
    class Render
      def initialize(obj, options, serializer:, collection:)
        @obj = obj
        @options = options
        @serializer = serializer
        @collection = collection
      end

      def to_hash
        instance_cache = InstanceCache.new
        # TODO hook: pre_render or similar
        if @collection
          @obj.each.map { |o| @serializer.call(o, @options, instance_cache) }
        else
          @serializer.call(@obj, @options, instance_cache)
        end
      end

      def to_json
        # TODO MultiJson.dump to_hash
        to_hash.to_json
      end
    end
  end
end
