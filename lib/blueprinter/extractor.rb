# frozen_string_literal: true

module Blueprinter
  class Extractor
    def self.extract(field_name, object, local_options, options = {})
      new.extract(field_name, object, local_options, options)
    end

    def extract(_field_name, _object, _local_options, _options = {})
      raise NotImplementedError, 'An Extractor must implement #extract'
    end

    private

    def default_extractor
      Blueprinter.configuration.extractor_default.new
    end
  end
end
