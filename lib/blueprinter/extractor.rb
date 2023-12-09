# frozen_string_literal: true

module Blueprinter
  class Extractor
    def extract(_field_name, _object, _local_options, _options = {})
      raise NotImplementedError, 'An Extractor must implement #extract'
    end

    def self.extract(field_name, object, local_options, options = {})
      new.extract(field_name, object, local_options, options)
    end
  end
end
