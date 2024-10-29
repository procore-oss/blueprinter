# frozen_string_literal: true

require 'blueprinter/blueprinter_error'

module Blueprinter
  module Errors
    class InvalidRoot < BlueprinterError
      def initialize(message = 'root key must be a Symbol or a String')
        super
      end
    end
  end
end
