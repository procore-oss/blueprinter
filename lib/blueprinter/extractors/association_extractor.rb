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
        extract_v2(value, blueprint, local_options, options)
      else
        blueprint.hashify(value, view_name: view, local_options: local_options)
      end
    end

    private

    def extract_v2(value, blueprint, local_options, options)
      view = options[:view] || :default
      stores = (local_options[:v2_stores] ||= V2::Context.create_stores)
      instances = (local_options[:v2_instances] ||= V2::InstanceCache.new)
      if value.is_a?(Enumerable) && !value.is_a?(Hash)
        blueprint[view].serializer.collection(value, local_options, instances, stores)
      else
        blueprint[view].serializer.object(value, local_options, instances, stores)
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
