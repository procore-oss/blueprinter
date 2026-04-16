# frozen_string_literal: true

require 'blueprinter/extractor'
require 'blueprinter/empty_types'

module Blueprinter
  # @api private
  class AssociationExtractor < Extractor
    include EmptyTypes

    def initialize
      @extractor = Blueprinter.configuration.default_extractor
    end

    def extract(association_name, object, local_options, options = {})
      options_without_default = if options.key?(:default) || options.key?(:default_if)
                                  options.except(:default, :default_if)
                                else
                                  options
                                end

      value = @extractor.extract(association_name, object, local_options, options_without_default)
      return default_value(options) if use_default_value?(value, options[:default_if])

      # Merge in association options - supports both static Hash and dynamic Proc
      local_options = merge_association_options(local_options, options[:options], object)

      view = options[:view] || :default
      blueprint = association_blueprint(options[:blueprint], value)
      blueprint.hashify(value, view_name: view, local_options:)
    end

    private

    def merge_association_options(local_options, association_options, object)
      return local_options unless association_options

      additional_options = if association_options.respond_to?(:call)
                             association_options.call(object)
                           else
                             association_options
                           end

      local_options.merge(additional_options)
    end

    def default_value(association_options)
      return association_options.fetch(:default) if association_options.key?(:default)

      Blueprinter.configuration.association_default
    end

    def association_blueprint(blueprint, value)
      blueprint.is_a?(Proc) ? blueprint.call(value) : blueprint
    end
  end
end
