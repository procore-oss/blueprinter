# frozen_string_literal: true

module Blueprinter
  module V2
    # Common methods for Field and ConfigurableField
    module FieldHelpers
      # @return [true | false] Returns true if this is a regular field
      def field? = type == :field

      # @return [true | false] Returns true if this is an object field
      def object? = type == :object

      # @return [true | false] Returns true if this is a collection field
      def collection? = type == :collection

      # @return [true | false] Returns true if this is an object or collection field
      def association? = object? || collection?
    end

    # A field or association definition.
    #
    # @!attribute [r] type
    #   @return [:field | :object | :collection] The type of field
    # @!attribute [r] name
    #   @return [Symbol] Name of field in result
    # @!attribute [r] source
    #   @return [Symbol] Method name/Hash key to pull the field value from
    # @!attribute [r] source_str
    #   @return [String] Same as `source` but a string
    # @!attribute [r] value_proc
    #   @return [Proc | nil] A proc to extract the value
    # @!attribute [r] options
    #   @return [Hash] Options defined on the field
    # @!attribute [r] blueprint
    #   @return [Class | nil] Blueprint to serialize with (objects and collections only)
    # @!attribute [r] _merged_options
    #   @return Internal - DO NOT USE
    # @!attribute [r] _has_conditional
    #   @return Internal - DO NOT USE
    # @!attribute [r] _has_default
    #   @return Internal - DO NOT USE
    # @!attribute [r] _extractor
    #   @return Internal - DO NOT USE
    # @!attribute [r] _serializer
    #   @return Internal - DO NOT USE
    Field = Struct.new(
      :type,
      :name,
      :source,
      :source_str,
      :options,
      :value_proc,
      :blueprint,
      :_merged_options,
      :_has_conditional,
      :_has_default,
      :_extractor,
      :_serializer,
      keyword_init: true
    ) do
      include FieldHelpers

      # Returns a copy of this field that extensions can modify
      # @!visibility private
      def to_configurable
        ConfigurableField.new(type, name, source, options.dup, value_proc, blueprint, self)
      end
    end

    # Representation of a field that's modifiable inside `around_blueprint_init` hooks.
    #
    # @!attribute [r] type
    #   @return [:field | :object | :collection] The type of field
    # @!attribute [rw] name
    #   @return [Symbol] Name of field in result
    # @!attribute [rw] source
    #   @return [Symbol] Method name/Hash key to pull the field value from
    # @!attribute [rw] options
    #   @return [Hash] Options defined on the field
    # @!attribute [rw] value_proc
    #   @return [Proc | nil] A proc to extract the value
    # @!attribute [r] blueprint
    #   @return [Class | nil] Blueprint to serialize with (objects and collections only)
    ConfigurableField = Struct.new(:type, :name, :source, :options, :value_proc, :blueprint, :_original) do
      include FieldHelpers

      # @!visibility private
      def to_internal
        Field.new(
          type:,
          name: name.to_sym,
          source: source.to_sym,
          source_str: source == original.source ? original.source_str : source.to_s,
          options:,
          value_proc:,
          blueprint:
        )
      end

      # Remove setters from field that shouldn't be changed
      %i[type blueprint _original].each { |member| remove_method "#{member}=" }

      # rubocop:disable Lint/UselessAccessModifier, Layout/EmptyLinesAroundAccessModifier
      private
      # rubocop:enable Lint/UselessAccessModifier, Layout/EmptyLinesAroundAccessModifier

      # Ensure the original field can only be referenced from a private method
      alias_method :original, :_original
      remove_method :_original
    end
  end
end
