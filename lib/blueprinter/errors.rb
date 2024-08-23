# frozen_string_literal: true

module Blueprinter
  module Errors
    autoload :InvalidBlueprint, 'blueprinter/errors/invalid_blueprint'
    autoload :UnknownPartial, 'blueprinter/errors/unknown_partial'
    autoload :UnknownView, 'blueprinter/errors/unknown_view'
  end
end
