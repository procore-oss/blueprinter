module Blueprinter
  class DateTimeFormatter
    InvalidDateTimeFormatterError = Class.new(BlueprinterError)

    def format(value, options)
      return value if value.nil? || !(field_format = options[:datetime_format] || Blueprinter.configuration.datetime_format)

      if value.respond_to?(:strftime)
        value = format_datetime(value, field_format)
      elsif options[:datetime_format]
        raise InvalidDateTimeFormatterError, 'Cannot format invalid DateTime object'
      end
      value
    end

    private

    def format_datetime(value, field_format)
      case field_format
      when Proc then field_format.call(value)
      when String then value.strftime(field_format)
      else
        raise InvalidDateTimeFormatterError, 'Cannot format DateTime object with invalid formatter: #{field_format.class}'
      end
    end
  end
end
