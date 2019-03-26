module Blueprinter
  class DateTimeFormatter
    def extract(value, options)
      if value.respond_to?(:utc)
        value = to_utc(value)
      end
      format_datetime(value, options)
    end

    private
    
    def to_utc(value)
      Blueprinter.configuration.utc ? value.utc : value
    end

    def format_datetime(value, options)
      return nil if value.nil?
      options.key?(:datetime_format) ? value.strftime(options[:datetime_format]) : value
    rescue NoMethodError
      raise BlueprinterError, 'Cannot format invalid DateTime object'
    end
  end
end
