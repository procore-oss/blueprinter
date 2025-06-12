# frozen_string_literal: true

module Blueprinter
  module V2
    module Fields
      Field = Struct.new(
        :name,
        :from,
        :from_str,
        :value_proc,
        :options,
        keyword_init: true
      ) do
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
        def type = :collection
      end
    end
  end
end
