# frozen_string_literal: true

require 'blueprinter/v2/instance_cache'
require 'blueprinter/v2/render'

module Blueprinter
  module V2
    # Render methods for V2
    module Rendering
      # Enumerable classes that `render` treats as objects instead of collections
      NON_COLLECTIONS = [Hash, Struct].freeze

      # True if `object` should be rendered as a collection instead of an object
      #
      # @param object [Object]
      # @return [true | false]
      #
      def self.collection?(object)
        object.is_a?(Enumerable) && NON_COLLECTIONS.none? { |klass| object.is_a?(klass) }
      end

      #
      # Serialize an object or collection (Enumerable) using this Blueprint.
      #
      #   # JSON string
      #   WidgetBlueprint.render(widget)
      #
      #   # Hash (or Array of Hashes)
      #   WidgetBlueprint.render(widget, format: :hash)
      #
      #   # A format added by an extension
      #   WidgetBlueprint.render(widget, format: :yaml)
      #
      # @param object [Object]
      # @param options [Hash] Render options
      # @option options [Symbol] :format The output format (default `:json`). Only `:json` and `:hash` are supported out
      # of the box. Extensions may add support for others or alter how `:json` and `:hash` are handled.
      # @option options [Symbol | String] :root Wrap result in a root object, keyed to this name
      # @option options [Object] :meta Add a `:meta` key to the root object and populate with the given value (only works
      # with `root`)
      # @return [Object] A JSON string, Hash/Array, or whatever `format` produces
      #
      def render(object, options = {})
        if Rendering.collection? object
          render_collection(object, options)
        else
          render_object(object, options)
        end
      end

      #
      # Serialize an object using this Blueprint.
      #
      #   WidgetBlueprint.render_object(widget)
      #   WidgetBlueprint.render_object(widget, format: :hash)
      #
      # @param object [Object]
      # @param options [Hash] Render options
      # @option options [Symbol] :format The output format (default `:json`; see {#render})
      # @option options [Symbol | String] :root Wrap result in a root object, keyed to this name
      # @option options [Object] :meta Add a `:meta` key to the root object and populate with the given value (only works
      # with `root`)
      # @return [Object] A JSON string, Hash, or whatever `format` produces
      #
      def render_object(object, options = {})
        options = options.dup
        format = options.delete(:format) || :json
        instances = InstanceCache.new
        Render.new(object, options, blueprint: self, instances:, collection: false).render(format)
      end

      #
      # Serialize a collection (Enumerable) using this Blueprint.
      #
      #   WidgetBlueprint.render_collection(Widget.all)
      #   WidgetBlueprint.render_collection(Widget.all, format: :hash)
      #
      # @param objects [Object]
      # @param options [Hash] Render options
      # @option options [Symbol] :format The output format (default `:json`; see {#render})
      # @option options [Symbol | String] :root Wrap result in a root object, keyed to this name
      # @option options [Object] :meta Add a `:meta` key to the root object and populate with the given value (only works
      # with `root`)
      # @return [Object] A JSON string, Array, or whatever `format` produces
      #
      def render_collection(objects, options = {})
        options = options.dup
        format = options.delete(:format) || :json
        instances = InstanceCache.new
        Render.new(objects, options, blueprint: self, instances:, collection: true).render(format)
      end

      #
      # Backwards-compatible with legacy/V1. Prefer `MyBlueprint.render(obj, format: :hash)`.
      #
      # @param objects [Object]
      # @param options [Hash] Render options
      # @option options [Symbol | String] :root Wrap result in a root object, keyed to this name
      # @option options [Object] :meta Add a `:meta` key to the root object and populate with the given value (only works
      # with `root`)
      # @return [Hash | Array]
      #
      def render_as_hash(objects, options = {})
        render(objects, options.merge(format: :hash))
      end

      #
      # Backwards-compatible with legacy/V1. Prefer `MyBlueprint.render(obj, format: :hash).as_json`.
      #
      # @param objects [Object]
      # @param options [Hash] Render options
      # @option options [Symbol | String] :root Wrap result in a root object, keyed to this name
      # @option options [Object] :meta Add a `:meta` key to the root object and populate with the given value (only works
      # with `root`)
      # @return [Hash | Array]
      #
      def render_as_json(objects, options = {})
        render(objects, options.merge(format: :hash)).as_json
      end
    end
  end
end
