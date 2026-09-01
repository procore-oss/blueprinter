# frozen_string_literal: true

require 'blueprinter/v2/instance_cache'
require 'blueprinter/v2/render'

module Blueprinter
  module V2
    # Render methods for V2
    module Rendering
      #
      # Serialize an object or collection (Enumerable) using this Blueprint.
      #
      # Call `to_json`, `to_hash`, or `to(format)` on the return value to get the final serialized value.
      #
      #   WidgetBlueprint.render(widget).to_json
      #
      # In Rails controllers rendering JSON, `to_json` is not required, making it compatible with V1:
      #
      #   render json: WidgetBlueprint.render(widget)
      #
      # @param object [Object]
      # @param options [Hash] Render options
      # @option options [Symbol | String] :root Wrap result in a root object, keyed to this name
      # @option options [Object] :meta Add a `:meta` key to the root object and populate with the given value (only works
      # with `root`)
      # @return [Blueprinter::V2::Render]
      #
      def render(object, options = {})
        if object.is_a?(Enumerable) && !object.is_a?(Hash)
          render_collection(object, options)
        else
          render_object(object, options)
        end
      end

      #
      # Serialize an object using this Blueprint.
      #
      # Call `to_json`, `to_hash`, or `to(format)` on the return value to get the final serialized value.
      #
      #   WidgetBlueprint.render_object(widget).to_json
      #
      # @param object [Object]
      # @param options [Hash] Render options
      # @option options [Symbol | String] :root Wrap result in a root object, keyed to this name
      # @option options [Object] :meta Add a `:meta` key to the root object and populate with the given value (only works
      # with `root`)
      # @return [Blueprinter::V2::Render]
      #
      def render_object(object, options = {})
        instances = InstanceCache.new
        Render.new(object, options, blueprint: self, instances:, collection: false)
      end

      #
      # Serialize a collection (Enumerable) using this Blueprint.
      #
      # Call `to_json`, `to_hash`, or `to(format)` on the return value to get the final serialized value.
      #
      #   WidgetBlueprint.render_collection(Widget.all).to_json
      #
      # @param objects [Object]
      # @param options [Hash] Render options
      # @option options [Symbol | String] :root Wrap result in a root object, keyed to this name
      # @option options [Object] :meta Add a `:meta` key to the root object and populate with the given value (only works
      # with `root`)
      # @return [Blueprinter::V2::Render]
      #
      def render_collection(objects, options = {})
        instances = InstanceCache.new
        Render.new(objects, options, blueprint: self, instances:, collection: true)
      end

      #
      # Backwards-compatible with legacy/V1. Prefer `MyBlueprint.render(obj).to_hash`.
      #
      # @param objects [Object]
      # @param options [Hash] Render options
      # @option options [Symbol | String] :root Wrap result in a root object, keyed to this name
      # @option options [Object] :meta Add a `:meta` key to the root object and populate with the given value (only works
      # with `root`)
      # @return [Hash | Array]
      #
      def render_as_hash(objects, options = {})
        render(objects, options).to_hash
      end

      #
      # Backwards-compatible with legacy/V1. Prefer `MyBlueprint.render(obj).to_hash.as_json`.
      #
      # @param objects [Object]
      # @param options [Hash] Render options
      # @option options [Symbol | String] :root Wrap result in a root object, keyed to this name
      # @option options [Object] :meta Add a `:meta` key to the root object and populate with the given value (only works
      # with `root`)
      # @return [Hash | Array]
      #
      def render_as_json(objects, options = {})
        render(objects, options).to_hash.as_json
      end
    end
  end
end
