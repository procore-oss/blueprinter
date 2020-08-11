module Blueprinter
  # @api private
  class AssociationExtractor < Extractor
    include EmptyTypes

    def initialize
      @extractor = Blueprinter.configuration.extractor_default.new
    end

    def extract(association_name, object, local_options, options = {})
      options_without_default = options.reject { |k, _| k == :default || k == :default_if }
      # Merge in assocation options hash
      local_options = local_options.merge(options[:options]) if options[:options].is_a?(Hash)
      value = @extractor.extract(association_name, object, local_options, options_without_default)
      return default_value(options) if use_default_value?(value, options[:default_if])
      view = options[:view] || :default
      blueprint = association_blueprint(options[:blueprint], value, association_name)
      blueprint.prepare(value, view_name: view, local_options: local_options)
    end

    private

    def default_value(association_options)
      association_options.key?(:default) ? association_options.fetch(:default) : Blueprinter.configuration.association_default
    end

    def association_blueprint(blueprint, value, association_name)
      if blueprint.is_a?(Proc)
        blueprint.call(value)
      else
        validate_blueprint_has_ancestors(blueprint, association_name)
        validate_blueprinter_has_correct_ancestor(blueprint, association_name)
        blueprint
      end
    end

    def validate_blueprint_has_ancestors(blueprint, association_name)
      # If the class passed as a blueprint does not respond to ancestors
      # it means it, at the very least, does not have Blueprinter::Base as
      # one of its ancestor classes (e.g: Hash) and thus an error should
      # be raised.
      unless blueprint.respond_to?(:ancestors)
        raise BlueprinterError, "Blueprint provided for #{association_name} "\
                                'association is not valid.'
      end
    end

    def validate_blueprinter_has_correct_ancestor(blueprint, association_name)
      # Guard clause in case Blueprinter::Base is present in the ancestor list
      # for the blueprint class provided.
      return if blueprint.ancestors.include? Blueprinter::Base

      # Raise error describing what's wrong.
      raise BlueprinterError, "Class #{blueprint.name} does not inherit from "\
                              'Blueprinter::Base and is not a valid Blueprinter '\
                              "for #{association_name} association."
    end
  end
end
