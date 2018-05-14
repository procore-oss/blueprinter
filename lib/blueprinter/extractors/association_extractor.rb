module Blueprinter
  class AssociationExtractor < Extractor
    def extract(association_name, object, local_options, options={})
      value = object.public_send(association_name) || options[:default]
      return value if value.blank?
      view = options[:view] || :default
      options[:blueprint].prepare(value, view_name: view, local_options: local_options)
    end
  end
end
