# @api private
module Blueprinter
  class Extractor
    def extract(field_name, object, local_options, options={})
      fail NotImplementedError, "An Extractor must implement #extract"
    end

    def self.extract(field_name, object, local_options, options={})
      self.new.extract(field_name, object, local_options, options)
    end
  end
end
