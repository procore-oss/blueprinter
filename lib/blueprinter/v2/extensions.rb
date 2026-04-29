# frozen_string_literal: true

module Blueprinter
  module V2
    # @!visibility private
    module Extensions
      # Core functionality built with extensions
      # @!visibility private
      module Core
        autoload :Json, 'blueprinter/v2/extensions/core/json'
        autoload :Wrapper, 'blueprinter/v2/extensions/core/wrapper'
      end
    end
  end
end
