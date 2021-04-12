module Blueprinter
  class Extractor
    def extract(_field_name, _object, _local_options, _options={})
      fail NotImplementedError, "An Extractor must implement #extract"
    end

    def self.extract(field_name, object, local_options, options={})
      self.new.extract(field_name, object, local_options, options)
    end

    def cache_key
      self.class.to_s
    end
  end
end
