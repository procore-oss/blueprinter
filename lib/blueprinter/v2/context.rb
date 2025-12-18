# frozen_string_literal: true

module Blueprinter
  module V2
    # Defines structs passed to extension hooks, extractors, and field blocks.
    module Context
      #
      # The blueprint being rendered along with options passed to render/render_object/render_collection.
      #
      # @!attribute [r] blueprint
      #   @return [Blueprinter::V2::Base] Instance of the outer Blueprint class
      # @!attribute [r] fields
      #   @return [Array<Blueprinter::V2::Fields::*>]
      # @!attribute [r] options
      #   @return [Hash] Options passed to `render`
      #
      Render = Struct.new(:blueprint, :fields, :options, :store, :depth) do
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
      #   @return [Array<Blueprinter::V2::Fields::*>]
      # @!attribute [r] options
      #   @return [Hash] Options passed to `render`
      # @!attribute [r] extension
      #   @return [Blueprinter::Extension] Instance of the extension running
      # @!attribute [r] hook
      #   @return [Symbol] Name of the symbol being called
      # @!attribute [r] depth
      #   @return [Integer] Blueprint depth (1-indexed)
      #
      Hook = Struct.new(:blueprint, :fields, :options, :extension, :hook, :store, :depth) do
        members.each do |attr|
          remove_method("#{attr}=")
          define_method("#{attr}=") { |_| raise BlueprinterError, "Context field `#{attr}` is immutable" }
        end
      end

      #
      # The object or collection currently being serialized.
      #
      # @!attribute [r] blueprint
      #   @return [Blueprinter::V2::Base] Instance of the current Blueprint class
      # @!attribute [r] fields
      #   @return [Array<Blueprinter::V2::Fields::*>]
      # @!attribute [r] options
      #   @return [Hash] Options passed to `render`
      # @!attribute [r] object
      #   @return [Object] The object or collection that's currently being rendered
      # @!attribute [r] parent
      #   @return [Blueprinter::V2::Context::Parent] Information about the parent, if any
      # @!attribute [r] depth
      #   @return [Integer] Blueprint depth (1-indexed)
      #
      Object = Struct.new(:blueprint, :fields, :options, :object, :parent, :store, :depth) do
        (members - %i[object]).each do |attr|
          remove_method("#{attr}=")
          define_method("#{attr}=") { |_| raise BlueprinterError, "Context field `#{attr}` is immutable" }
        end
      end

      Parent = Struct.new(:blueprint, :field, :object) do
        members.each do |attr|
          remove_method("#{attr}=")
          define_method("#{attr}=") { |_| raise BlueprinterError, "Parent field `#{attr}` is immutable" }
        end
      end

      #
      # The current field.
      #
      # @!attribute [r] blueprint
      #   @return [Blueprinter::V2::Base] Instance of the current Blueprint class
      # @!attribute [r] fields
      #   @return [Array<Blueprinter::V2::Fields::*>]
      # @!attribute [r] options
      #   @return [Hash] Options passed to `render`
      # @!attribute [r] object
      #   @return [Object] The object or collection that's currently being rendered
      # @!attribute [r] field
      #   @return [Blueprinter::V2::Fields::Field|Blueprinter::V2::Fields::Object|Blueprinter::V2::Fields::Collection] The
      # field that's currently being evaluated
      # @!attribute [r] depth
      #   @return [Integer] Blueprint depth (1-indexed)
      #
      Field = Struct.new(:blueprint, :fields, :options, :object, :field, :store, :depth) do
        (members - %i[field]).each do |attr|
          remove_method("#{attr}=")
          define_method("#{attr}=") { |_| raise BlueprinterError, "Context field `#{attr}` is immutable" }
        end
      end

      #
      # A serialized object/collection. This may be the outer object/collection or a nested one.
      #
      # @!attribute [r] blueprint
      #   @return [Blueprinter::V2::Base] Instance of the current Blueprint class
      # @!attribute [r] fields
      #   @return [Array<Blueprinter::V2::Fields::*>]
      # @!attribute [r] options
      #   @return [Hash] Options passed to `render`
      # @!attribute [r] object
      #   @return [Object] The object or collection that's currently being rendered
      # @!attribute [r] format
      #   @return [Symbol] Requested format of result, e.g. :json
      #
      Result = Struct.new(:blueprint, :fields, :options, :object, :format, :store) do
        (members - %i[blueprint options object format]).each do |attr|
          remove_method("#{attr}=")
          define_method("#{attr}=") { |_| raise BlueprinterError, "Context field `#{attr}` is immutable" }
        end
      end

      # Represents the final result of a render call that shouldn't be further modified by extensions
      Final = Struct.new(:value)
    end
  end
end
