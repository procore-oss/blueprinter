# frozen_string_literal: true

require 'blueprinter/extractor'
require 'blueprinter/empty_types'

module Blueprinter
  # @api private
  class AssociationExtractor < Extractor
    include EmptyTypes

    def initialize
      @extractor = Blueprinter.configuration.extractor_default.new
    end

    def extract(association_name, object, local_options, options = {})
      options_without_default = options.except(:default, :default_if)
      # Merge in assocation options hash
      local_options = local_options.merge(options[:options]) if options[:options].is_a?(Hash)
      value = @extractor.extract(association_name, object, local_options, options_without_default)
      return default_value(options) if use_default_value?(value, options[:default_if])

      view = options[:view] || :default
      blueprint = association_blueprint(options[:blueprint], value)
      if blueprint <= V2::Base
        view = options[:view] || :default
        store = local_options.fetch(:v2_store)
        instances = local_options.fetch(:v2_instances)
        if value.is_a?(Enumerable) && !value.is_a?(Hash)
          blueprint[view].serializer.collection(value, local_options, instances, store)
        else
          blueprint[view].serializer.object(value, local_options, instances, store)
        end
      else
        blueprint.prepare(value, view_name: view, local_options: local_options)
      end
    end

    private

    def default_value(association_options)
      return association_options.fetch(:default) if association_options.key?(:default)

      Blueprinter.configuration.association_default
    end

    def association_blueprint(blueprint, value)
      blueprint.is_a?(Proc) ? blueprint.call(value) : blueprint
    end
  end
end
