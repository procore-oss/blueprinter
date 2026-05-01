# frozen_string_literal: true

module Blueprinter
  module V2
    module Fields
      module Helpers
        # @return [True|False] Returns true if this is a regular field
        def field? = type == :field

        # @return [True|False] Returns true if this is an object field
        def object? = type == :object

        # @return [True|False] Returns true if this is a collection field
        def collection? = type == :collection
      end

      # A non-object, non-collection field definition.
      #
      # @!attribute [r] name
      #   @return [Symbol] Name of field in result
      # @!attribute [r] source
      #   @return [Symbol] Method name/Hash key to pull the field value from
      # @!attribute [r] source_str
      #   @return [String] Same as `source` but a string
      # @!attribute [r] value_proc
      #   @return [Proc|NilClass] A proc to extract the value
      # @!attribute [r] options
      #   @return [Hash] Options defined on the field
      Field = Struct.new(
        :name,
        :source,
        :source_str,
        :value_proc,
        :options,
        :_merged_options,
        :_has_conditional,
        :_has_default,
        :_extractor,
        keyword_init: true
      ) do
        include Helpers

        # @return [Symbol] :field
        def type = :field
      end

      # An object field definition.
      #
      # @!attribute [r] name
      #   @return [Symbol] Name of field in result
      # @!attribute [r] source
      #   @return [Symbol] Method name/Hash key to pull the field value from
      # @!attribute [r] source_str
      #   @return [String] Same as `source` but a string
      # @!attribute [r] value_proc
      #   @return [Proc|NilClass] A proc to extract the value
      # @!attribute [r] options
      #   @return [Hash] Options defined on the field
      # @!attribute [r] blueprint
      #   @return [Class] Blueprint to serialize with
      Object = Struct.new(
        :name,
        :blueprint,
        :source,
        :source_str,
        :value_proc,
        :options,
        :_merged_options,
        :_has_conditional,
        :_has_default,
        :_extractor,
        :_serializer,
        keyword_init: true
      ) do
        include Helpers

        # @return [Symbol] :object
        def type = :object
      end

      # A collection field definition.
      #
      # @!attribute [r] name
      #   @return [Symbol] Name of field in result
      # @!attribute [r] source
      #   @return [Symbol] Method name/Hash key to pull the field value from
      # @!attribute [r] source_str
      #   @return [String] Same as `source` but a string
      # @!attribute [r] value_proc
      #   @return [Proc|NilClass] A proc to extract the value
      # @!attribute [r] options
      #   @return [Hash] Options defined on the field
      # @!attribute [r] blueprint
      #   @return [Class] Blueprint to serialize with
      Collection = Struct.new(
        :name,
        :blueprint,
        :source,
        :source_str,
        :value_proc,
        :options,
        :_merged_options,
        :_has_conditional,
        :_has_default,
        :_extractor,
        :_serializer,
        keyword_init: true
      ) do
        include Helpers

        # @return [Symbol] :collection
        def type = :collection
      end
    end
  end
end
