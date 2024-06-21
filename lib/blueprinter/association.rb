# frozen_string_literal: true

require_relative 'field'
require_relative 'blueprint_validator'

module Blueprinter
  # @api private
  class Association < Field
    # @param method [Symbol] The method to call on the source object to retrieve the associated data
    # @param name [Symbol] The name of the association as it will appear when rendered
    # @param blueprint [Blueprinter::Base] The blueprint to use for rendering the association
    # @param view [Symbol] The view to use in conjunction with the blueprint
    # @param extractor [Blueprinter::Extractor] The extractor to use when retrieving the associated data
    # @param options [Hash]
    #
    # @return [Blueprinter::Association]
    def initialize(method:, name:, blueprint:, view:, extractor: AssociationExtractor.new, options: {})
      BlueprintValidator.validate!(blueprint)

      super(
        method,
        name,
        extractor,
        blueprint,
        options.merge(
          blueprint: blueprint,
          view: view
        )
      )
    end
  end
end
