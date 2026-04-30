# frozen_string_literal: true

module Blueprinter
  module V2
    # Structs passed to if/unless/default Procs, field definition blocks, and extension hooks.
    module Context
      #
      # The blueprint being rendered along with options passed to render/render_object/render_collection.
      #
      # @!attribute [r] blueprint
      #   @return [Blueprinter::V2::Base] Instance of the outer Blueprint class
      # @!attribute [rw] fields
      #   @return [Array<Blueprinter::V2::Fields>] The fields to serialize, in order. Frozen, but can be replaced.
      # @!attribute [rw] options
      #   @return [Hash] Options passed to `render`. Frozen, but can be replaced.
      # @!attribute [r] store
      #   @return [Hash] Arbitrary store available for this render
      # @!attribute [r] depth
      #   @return [Integer] Current serialization depth
      #
      Init = Struct.new(:blueprint, :fields, :options, :store, :depth) do
        (members - %i[fields options]).each do |attr|
          remove_method("#{attr}=")
          define_method("#{attr}=") { |_| raise BlueprinterError, "Context field `#{attr}` is immutable" }
        end
      end

      #
      # The extension hook currently being called.
      #
      # @!attribute [r] blueprint
      #   @return [Blueprinter::V2::Base] Instance of the outer Blueprint class
      # @!attribute [r] fields
      #   @return [Array<Blueprinter::V2::Fields>]
      # @!attribute [r] options
      #   @return [Hash] Options passed to `render`
      # @!attribute [r] extension
      #   @return [Blueprinter::Extension] Instance of the extension running
      # @!attribute [r] hook
      #   @return [Symbol] Name of the symbol being called
      # @!attribute [r] depth
      #   @return [Integer] Blueprint depth (1-indexed)
      # @!attribute [r] store
      #   @return [Hash] Arbitrary store available for this render
      # @!attribute [r] depth
      #   @return [Integer] Current serialization depth
      #
      Hook = Struct.new(:blueprint, :fields, :options, :extension, :hook, :store, :depth)

      #
      # The object or collection currently being serialized.
      #
      # @!attribute [r] blueprint
      #   @return [Blueprinter::V2::Base] Instance of the current Blueprint class
      # @!attribute [r] fields
      #   @return [Array<Blueprinter::V2::Fields>]
      # @!attribute [r] options
      #   @return [Hash] Options passed to `render`
      # @!attribute [rw] object
      #   @return [Object] The object or collection that's currently being rendered. Can be replaced.
      # @!attribute [r] parent
      #   @return [Blueprinter::V2::Context::Parent] Information about the parent, if any
      # @!attribute [r] store
      #   @return [Hash] Arbitrary store available for this render
      # @!attribute [r] depth
      #   @return [Integer] Blueprint depth (1-indexed)
      #
      Object = Struct.new(:blueprint, :fields, :options, :object, :parent, :store, :depth) do
        (members - %i[object]).each do |attr|
          remove_method("#{attr}=")
          define_method("#{attr}=") { |_| raise BlueprinterError, "Context field `#{attr}` is immutable" }
        end
      end

      #
      # The parent blueprint, field, and object.
      #
      # @!attribute [r] blueprint
      #   @return [Blueprinter::V2::Base] The parent's Blueprint instance
      # @!attribute [r] field
      #   @return [Blueprinter::V2::Fields] The parent field
      # @!attribute [r] object
      #   @return [Object] The parent object
      #
      Parent = Struct.new(:blueprint, :field, :object) do
        (members - %i[field object]).each do |attr|
          remove_method("#{attr}=")
          define_method("#{attr}=") { |_| raise BlueprinterError, "Parent field `#{attr}` is immutable" }
        end
      end

      #
      # The field currently being serialized.
      #
      # @!attribute [r] blueprint
      #   @return [Blueprinter::V2::Base] Instance of the current Blueprint class
      # @!attribute [r] fields
      #   @return [Array<Blueprinter::V2::Fields>]
      # @!attribute [r] options
      #   @return [Hash] Options passed to `render`
      # @!attribute [r] object
      #   @return [Object] The object or collection that's currently being rendered
      # @!attribute [r] field
      #   @return [Blueprinter::V2::Fields::Field|Blueprinter::V2::Fields::Object|Blueprinter::V2::Fields::Collection] The
      #           field that's currently being evaluated
      # @!attribute [r] store
      #   @return [Hash] Arbitrary store available for this render
      # @!attribute [r] depth
      #   @return [Integer] Blueprint depth (1-indexed)
      #
      Field = Struct.new(:blueprint, :fields, :options, :object, :field, :store, :depth) do
        (members - %i[field object]).each do |attr|
          remove_method("#{attr}=")
          define_method("#{attr}=") { |_| raise BlueprinterError, "Context field `#{attr}` is immutable" }
        end
      end

      #
      # A serialized object/collection. This may be the outer object/collection or a nested one.
      #
      # @!attribute [rw] blueprint
      #   @return [Blueprinter::V2::Base] Instance of the current Blueprint class. If replaced, the render is aborted and a
      #           new one begun.
      # @!attribute [r] fields
      #   @return [Array<Blueprinter::V2::Fields>]
      # @!attribute [rw] options
      #   @return [Hash] Options passed to `render`. Can be replaced.
      # @!attribute [rw] object
      #   @return [Object] The object or collection that's currently being rendered. Can be replaced.
      # @!attribute [rw] format
      #   @return [Symbol] Requested format of result, e.g. :json. Can be replaced.
      # @!attribute [r] store
      #   @return [Hash] Arbitrary store available for this render
      #
      Result = Struct.new(:blueprint, :fields, :options, :object, :format, :store) do
        (members - %i[blueprint options object format]).each do |attr|
          remove_method("#{attr}=")
          define_method("#{attr}=") { |_| raise BlueprinterError, "Context field `#{attr}` is immutable" }
        end
      end

      # Represents the final result of a render call that shouldn't be further modified by extensions
      # @!attribute [r] value
      #   @return [Object]
      Final = Struct.new(:value)
    end
  end
end
