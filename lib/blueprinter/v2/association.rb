# frozen_string_literal: true

module Blueprinter
  module V2
    Association = Struct.new(
      :name,
      :blueprint,
      :collection,
      :legacy_view,
      :from,
      :value_proc,
      :options,
      keyword_init: true
    )
  end
end
