# frozen_string_literal: true

require 'blueprinter/v2/instance_cache'
require 'blueprinter/v2/render'

module Blueprinter
  module V2
    # Render methods for V2
    module Rendering
      def render(obj, options = {})
        if obj.is_a?(Enumerable) && !obj.is_a?(Hash)
          render_collection(obj, options)
        else
          render_object(obj, options)
        end
      end

      def render_object(obj, options = {})
        instances = InstanceCache.new
        Render.new(obj, options, blueprint: self, instances:, collection: false)
      end

      def render_collection(objs, options = {})
        instances = InstanceCache.new
        Render.new(objs, options, blueprint: self, instances:, collection: true)
      end

      def render_as_hash(obj, options = {})
        render(obj, options).to_hash
      end

      def render_as_json(obj, options = {})
        render(obj, options).to_hash.as_json
      end
    end
  end
end
