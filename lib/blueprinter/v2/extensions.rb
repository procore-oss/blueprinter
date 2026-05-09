# frozen_string_literal: true

module Blueprinter
  module V2
    # @!visibility private
    module Extensions
      # Core functionality built with extensions
      # @!visibility private
      module Core
        autoload :Format, 'blueprinter/v2/extensions/core/format'
        autoload :Root, 'blueprinter/v2/extensions/core/root'
      end
    end
  end
end
