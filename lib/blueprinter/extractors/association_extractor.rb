module Blueprinter
  class AssociationExtractor < Extractor
    def initialize
      @extractor = AutoExtractor.new
    end

    def extract(association_name, object, local_options, options={})
      value = @extractor.extract(association_name, object, local_options, options.except(:default))
      return default_value(options) if value.nil?
      view = options[:view] || :default
      blueprint = association_blueprint(options[:blueprint], value)
      blueprint.prepare(value, view_name: view, local_options: local_options)
    end

    private

    def default_value(field_options)
      field_options.key?(:default) ? field_options.fetch(:default) : Blueprinter.configuration.association_default
    end

    def association_blueprint(blueprint, value)
      blueprint.is_a?(Proc) ? blueprint.call(value) : blueprint
    end
  end
end
