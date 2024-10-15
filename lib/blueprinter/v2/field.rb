# frozen_string_literal: true

module Blueprinter
  module V2
    Field = Struct.new(
      :name,
      :from,
      :if_cond,
      :value_proc,
      :custom_options,
      keyword_init: true
    )
  end
end
