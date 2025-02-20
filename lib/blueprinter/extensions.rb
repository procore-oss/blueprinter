# frozen_string_literal: true

module Blueprinter
  # Optional extensions for applications to pull in
  module Extensions
    autoload :FieldOrder, 'blueprinter/extensions/field_order'
  end
end
