# frozen_string_literal: true

module Blueprinter
  module V2
    Association = Struct.new(
      :name,
      :blueprint,
      :collection,
      :legacy_view,
      :from,
      :if_cond,
      :value_proc,
      :extractor,
      :custom_options,
      keyword_init: true
    )
  end
end
