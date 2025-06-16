# frozen_string_literal: true

module Blueprinter
  module Errors
    autoload :ExtensionHook, 'blueprinter/errors/extension_hook'
    autoload :InvalidBlueprint, 'blueprinter/errors/invalid_blueprint'
    autoload :UnknownPartial, 'blueprinter/errors/unknown_partial'
    autoload :UnknownView, 'blueprinter/errors/unknown_view'
  end
end
