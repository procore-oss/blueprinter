# frozen_string_literal: true

require 'blueprinter/v2/instance_cache'

module Blueprinter
  module V2
    class Render
      def initialize(serializer, obj, options, collection)
        @serializer = serializer
        @obj = obj
        @options = options
        @collection = collection
      end

      def to_hash
        blueprint_instances = InstanceCache.new
        # TODO hook: pre_render or similar
        if @collection
          @obj.each.map { |o| @serializer.call(o, @options, blueprint_instances) }
        else
          @serializer.call(@obj, @options, blueprint_instances)
        end
      end

      def to_json
        # TODO MultiJson.dump to_hash
        to_hash.to_json
      end
    end
  end
end
