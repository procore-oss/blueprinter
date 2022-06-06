module Blueprinter
  class DateTimeFormatter
    InvalidDateTimeFormatterError = Class.new(BlueprinterError)

    def initialize
      @config_datetime_format = Blueprinter.configuration.datetime_format
    end

    def format(value, options)
      return value if value.nil? || !(options.key?(:datetime_format) || @config_datetime_format)

      field_format = options[:datetime_format]
      if value.respond_to?(:strftime)
        value = format_datetime(value, field_format)
      elsif field_format
        raise InvalidDateTimeFormatterError, 'Cannot format invalid DateTime object'
      end
      value
    end

    private

    def format_datetime(value, field_format)
      format = field_format || @config_datetime_format

      case format
      when NilClass then value
      when Proc then format.call(value)
      when String then value.strftime(format)
      else
        raise InvalidDateTimeFormatterError, 'Cannot format DateTime object with invalid formatter: #{format.class}'
      end
    end
  end
end
