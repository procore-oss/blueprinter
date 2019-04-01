module Blueprinter
  class DateTimeFormatter
    def format(value, options)
      return value if value.nil?
      
      field_format = options[:datetime_format]
      if value.respond_to?(:strftime)
        value = format_datetime(value, field_format)
      elsif field_format
        raise BlueprinterError, 'Cannot format invalid DateTime object'
      end
      value
    end

    private

    def format_datetime(value, field_format)
      format = field_format || Blueprinter.configuration.datetime_format
      format.nil? ? value : value.strftime(format)
    end
  end
end
