# frozen_string_literal: true

module Blueprinter
  module V2
    # Defines structs passed to extension hooks, extractors, and field blocks.
    module Context
      #
      # The outer blueprint being rendered along with options passed to render/render_object/render_collection.
      #
      # @!attribute [r] blueprint
      #   @return [Blueprinter::V2::Base] Instance of the outer Blueprint class
      # @!attribute [r] options
      #   @return [Hash] Options passed to `render`
      # @!attribute [r] instances
      #   @return [Blueprinter::V2::InstanceCache] An InstanceCache for sharing instances of Blueprints and Extractors during
      # a render
      # @!attribute [r] store
      #   @return [Hash] A Hash for extensions, etc to cache render data in
      #
      Render = Struct.new(:blueprint, :options, :instances, :store)

      #
      # The object or collection currently being serialized.
      #
      # @!attribute [r] blueprint
      #   @return [Blueprinter::V2::Base] Instance of the current Blueprint class
      # @!attribute [r] options
      #   @return [Hash] Options passed to `render`
      # @!attribute [r] instances
      #   @return [Blueprinter::V2::InstanceCache] An InstanceCache for sharing instances of Blueprints and Extractors during
      # a render
      # @!attribute [r] store
      #   @return [Hash] A Hash for extensions, etc to cache render data in
      # @!attribute [r] object
      #   @return [Object] The object or collection that's currently being rendered
      #
      Object = Struct.new(:blueprint, :options, :instances, :store, :object)

      #
      # The current field and its extracted value.
      #
      # @!attribute [r] blueprint
      #   @return [Blueprinter::V2::Base] Instance of the current Blueprint class
      # @!attribute [r] options
      #   @return [Hash] Options passed to `render`
      # @!attribute [r] instances
      #   @return [Blueprinter::V2::InstanceCache] An InstanceCache for sharing instances of Blueprints and Extractors during
      # a render
      # @!attribute [r] store
      #   @return [Hash] A Hash for extensions, etc to cache render data in
      # @!attribute [r] object
      #   @return [Object] The object or collection that's currently being rendered
      # @!attribute [r] field
      #   @return [Blueprinter::V2::Fields::Field|Blueprinter::V2::Fields::Object|Blueprinter::V2::Fields::Collection] The field that's
      # currently being evaluated
      # @!attribute [r] value
      #   @return [Object] The extracted field value
      #
      Field = Struct.new(:blueprint, :options, :instances, :store, :object, :field, :value)

      #
      # A serialized object/collection. This may be the outer object/collection or a nested one.
      #
      # @!attribute [r] blueprint
      #   @return [Blueprinter::V2::Base] Instance of the current Blueprint class
      # @!attribute [r] options
      #   @return [Hash] Options passed to `render`
      # @!attribute [r] instances
      #   @return [Blueprinter::V2::InstanceCache] An InstanceCache for sharing instances of Blueprints and Extractors during
      # a render
      # @!attribute [r] store
      #   @return [Hash] A Hash for extensions, etc to cache render data in
      # @!attribute [r] object
      #   @return [Object] The object or collection that's currently being rendered
      # @!attribute [r] result
      #   @return [Hash|Array<Hash>] A serialized result
      #
      Result = Struct.new(:blueprint, :options, :instances, :store, :object, :result)
    end
  end
end
