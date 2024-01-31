# frozen_string_literal: true

module Blueprinter
  #
  # Base class for all extensions. All extension methods are implemented as no-ops.
  #
  class Extension
    #
    # Called eary during "render", this method receives the object to be rendered and
    # may return a modified (or new) object to be rendered.
    #
    # @param object [Object] The object to be rendered
    # @param _blueprint [Class] The Blueprinter class
    # @param _view [Symbol] The blueprint view
    # @param _options [Hash] Options passed to "render"
    # @return [Object] The object to continue rendering
    #
    def pre_render(object, _blueprint, _view, _options)
      object
    end
  end
end
