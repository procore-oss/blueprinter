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

      Field = Struct.new(
        :name,
        :from,
        :from_str,
        :value_proc,
        :options,
        keyword_init: true
      ) do
        include Helpers

        # @return [Symbol] :field
        def type = :field
      end

      Object = Struct.new(
        :name,
        :blueprint,
        :from,
        :from_str,
        :value_proc,
        :options,
        keyword_init: true
      ) do
        include Helpers

        # @return [Symbol] :object
        def type = :object
      end

      Collection = Struct.new(
        :name,
        :blueprint,
        :from,
        :from_str,
        :value_proc,
        :options,
        keyword_init: true
      ) do
        include Helpers

        # @return [Symbol] :collection
        def type = :collection
      end
    end
  end
end
