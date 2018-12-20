module Blueprinter
  class AssociationExtractor < Extractor
    def initialize
      @extractor = AutoExtractor.new
    end

    def extract(association_name, object, local_options, options={})
      value = @extractor.extract(association_name, object, local_options, options.except(:default))
      return options[:default] if value.nil?
      view = options[:view] || :default
      association_blueprint(value, options).prepare(value, view_name: view, local_options: local_options)
    end
    
    private

    def association_blueprint(value, options)
      return options[:blueprint] unless options[:blueprint].is_a?(Proc)
      options[:blueprint].call(value)
    end
  end
end
