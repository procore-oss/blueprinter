# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      autoload :Postlude, 'blueprinter/v2/extensions/postlude'
      autoload :Prelude, 'blueprinter/v2/extensions/prelude'
      autoload :Exclusions, 'blueprinter/v2/extensions/exclusions'
      autoload :FieldOrder, 'blueprinter/v2/extensions/field_order'
      autoload :Values, 'blueprinter/v2/extensions/values'
    end
  end
end
