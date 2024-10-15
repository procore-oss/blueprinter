# frozen_string_literal: true

require 'blueprinter/blueprinter_error'

module Blueprinter
  module Errors
    class MetaRequiresRoot < BlueprinterError
      def initialize(message = 'adding metadata requires that a root key is set')
        super
      end
    end
  end
end
