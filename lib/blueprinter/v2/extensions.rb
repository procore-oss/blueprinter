# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      # Core functionality built with extensions
      module Core
        autoload :Exclusions, 'blueprinter/v2/extensions/core/exclusions'
        autoload :Postlude, 'blueprinter/v2/extensions/core/postlude'
        autoload :Prelude, 'blueprinter/v2/extensions/core/prelude'
        autoload :Values, 'blueprinter/v2/extensions/core/values'
      end
    end
  end
end
