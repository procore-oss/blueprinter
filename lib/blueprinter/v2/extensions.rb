# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      autoload :Exclusions, 'blueprinter/v2/extensions/exclusions'
      autoload :Output, 'blueprinter/v2/extensions/output'
      autoload :Values, 'blueprinter/v2/extensions/values'
    end
  end
end
