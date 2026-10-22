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
      if blueprint <= V2::Base
        extract_v2(value, blueprint, local_options, options)
      else
        blueprint.hashify(value, view_name: view, local_options:)
      end
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

    def extract_v2(value, blueprint, local_options, options)
      view = options[:view] || :default
      state = V2::V1Bridge.current
      args = { instances: state.instances, store: state.store || {}, depth: state.depth + 1 }
      if V2::Rendering.collection? value
        blueprint[view].serializer.collection(value, local_options, **args)
      else
        blueprint[view].serializer.object(value, local_options, **args)
      end
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
