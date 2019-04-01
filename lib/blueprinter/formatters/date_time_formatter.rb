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

      if format.nil?
        value
      elsif format.is_a?(Proc)
        format.call(value)
      elsif format.is_a?(String)
        value.strftime(format)
      else
        raise BlueprinterError, 'Cannot format DateTime object with invalid formatter'
      end
    end
  end
end
