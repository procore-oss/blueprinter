module Blueprinter
  class DateTimeFormatter
    def extract(value, options)
      if value.respond_to?(:utc)
        value = format_datetime(to_utc(value), options)
      end
      value
    end

    private
    
    def to_utc(datetime)
      Blueprinter.configuration.utc ? datetime.utc : datetime
    end

    def format_datetime(datetime, format)
      options.key?(:datetime_format) ? datetime.strftime(options[:datetime_format]) : datetime
    end
  end
end
