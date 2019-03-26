module Blueprinter
  # @api private
  class Formatter
    def format(field_name, object, local_options, options={})
      fail NotImplementedError, "A Formatter must implement #format"
    end

    def self.format(field_name, object, local_options, options={})
      self.new.format(field_name, object, local_options, options)
    end
  end
end
