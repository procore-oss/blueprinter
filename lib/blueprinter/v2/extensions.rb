# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      # Core functionality built with extensions
      module Core
        autoload :Json, 'blueprinter/v2/extensions/core/json'
        autoload :Root, 'blueprinter/v2/extensions/core/root'
      end
    end
  end
end
