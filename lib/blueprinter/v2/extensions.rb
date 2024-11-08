# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      autoload :Collections, 'blueprinter/v2/extensions/collections'
      autoload :Exclusions, 'blueprinter/v2/extensions/exclusions'
      autoload :FieldOrder, 'blueprinter/v2/extensions/field_order'
      autoload :Output, 'blueprinter/v2/extensions/output'
      autoload :Values, 'blueprinter/v2/extensions/values'
    end
  end
end
