module Blueprinter
  class AssociationExtractor < Extractor
    def initialize
      @extractor = AutoExtractor.new
    end

    def extract(association_name, object, local_options, options={})
      if options.key?(:default)
        value = @extractor.extract(association_name, object, local_options, options.except(:default))
        return options[:default] if value.nil?
      else
        value = @extractor.extract(association_name, object, local_options, options)
        return options[:default] if value.nil?
        view = options[:view] || :default
        options[:blueprint].prepare(value, view_name: view, local_options: local_options)
      end
    end
  end
end
