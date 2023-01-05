# frozen_string_literal: true

module Blueprinter
  # @api private
  class AssociationExtractor < Extractor
    include EmptyTypes

    def initialize
      @extractor = Blueprinter.configuration.extractor_default.new
    end

    def extract(association_name, object, local_options, options={})
      options_without_default = options.reject { |k,_| k == :default || k == :default_if }
      # Merge in assocation options hash
      local_options = local_options.merge(options[:options]) if options[:options].is_a?(Hash)
      value = @extractor.extract(association_name, object, local_options, options_without_default)
      return default_value(options) if use_default_value?(value, options[:default_if])
      view = options[:view] || :default
      blueprint = association_blueprint(options[:blueprint], value)
      blueprint.prepare(value, view_name: view, local_options: local_options)
    end

    private

    def default_value(association_options)
      association_options.key?(:default) ? association_options.fetch(:default) : Blueprinter.configuration.association_default
    end

    def association_blueprint(blueprint, value)
      blueprint.is_a?(Proc) ? blueprint.call(value) : blueprint
    end
  end
end
