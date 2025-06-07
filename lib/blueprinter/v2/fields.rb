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
      )

      Object = Struct.new(
        :name,
        :blueprint,
        :from,
        :from_str,
        :value_proc,
        :options,
        keyword_init: true
      )

      Collection = Struct.new(
        :name,
        :blueprint,
        :from,
        :from_str,
        :value_proc,
        :options,
        keyword_init: true
      )
    end
  end
end
