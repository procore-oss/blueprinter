# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      # Core functionality built with extensions
      module Core
        autoload :Conditionals, 'blueprinter/v2/extensions/core/conditionals'
        autoload :Defaults, 'blueprinter/v2/extensions/core/defaults'
        autoload :Extractor, 'blueprinter/v2/extensions/core/extractor'
        autoload :Postlude, 'blueprinter/v2/extensions/core/postlude'
        autoload :Prelude, 'blueprinter/v2/extensions/core/prelude'
      end
    end
  end
end
