# frozen_string_literal: true

module Blueprinter
  module V2
    Field = Struct.new(
      :name,
      :from,
      :value_proc,
      :options,
      keyword_init: true
    )
  end
end
