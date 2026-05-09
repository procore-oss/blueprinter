# frozen_string_literal: true

module Blueprinter
  module V2
    # Representaions of declared fields
    module Fields
      # Common methods for Field and Configurable
      module Helpers
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
        include Helpers

        # Returns a copy of this field that extensions can modify
        # @!visibility private
        def to_configurable
          Configurable.new(type, name, source, options.dup, value_proc, blueprint, self)
        end
      end

      # Representation of a field that's modifiable inside `around_blueprint_init` hooks.
      #
      # Altering a configurable field will change how it behaves during the current render.
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
      # @!attribute [r] _original
      #   @return Internal - DO NOT USE
      Configurable = Struct.new(:type, :name, :source, :options, :value_proc, :blueprint, :_original) do
        include Helpers

        # Remove setters from field that shouldn't be changed
        static_members = %i[type blueprint _original]
        dynamic_members = members - static_members
        static_members.each { |member| remove_method "#{member}=" }

        # @!visibility private
        def changed?
          @changed || options != _original.options
        end

        # @!visibility private
        def to_internal
          Field.new(
            type:,
            name: name.to_sym,
            source: source.to_sym,
            source_str: source == _original.source ? _original.source_str : source.to_s,
            options:,
            value_proc:,
            blueprint:
          )
        end

        # rubocop:disable Lint/UselessAccessModifier

        private

        # rubocop:enable Lint/UselessAccessModifier

        dynamic_members.each do |member|
          alias_method :"set_#{member}", :"#{member}="
        end

        public

        dynamic_members.each do |member|
          define_method :"#{member}=" do |val|
            @changed = true
            send(:"set_#{member}", val)
          end
        end
      end
    end
  end
end
