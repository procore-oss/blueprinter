module Blueprinter
  class DateTimeFormatter
    def extract(value, options)
      if value.respond_to?(:strftime)
        value = format_datetime(value, options)
      end
      value
    end

    private

    def format_datetime(value, options)
      format = options[:datetime_format] || Blueprinter.configuration.datetime_format
      return value if value.nil? || format.nil?
      value.strftime(format)
    end
  end
end
