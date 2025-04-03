# frozen_string_literal: true

module Blueprinter
  class V2
    Options = Struct.new(
      :exclude_nil,
      keyword_init: true
    )

    DEFAULT_OPTIONS = {
      exclude_nil: false
    }.freeze
  end
end
