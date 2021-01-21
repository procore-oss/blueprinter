# frozen_string_literal: true

module Blueprinter
  class Extractor
    FieldExtractionError = Class.new(BlueprinterError)

    def extract(_field_name, _object, _local_options, _options = {})
      raise NotImplementedError, 'An Extractor must implement #extract'
    end

    def self.extract(field_name, object, local_options, options = {})
      new.extract(field_name, object, local_options, options)
    rescue StandardError
      raise Blueprinter::Extractor::FieldExtractionError, "Error when extracting value for field: '#{field_name}'"
    end
  end
end
