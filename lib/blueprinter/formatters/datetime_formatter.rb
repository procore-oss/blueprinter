module Blueprinter
  class DateTimeFormatter < Formatter
    def format(datetime, options = {})
      return nil if datetime.nil?

      format = options[:datetime_format]

      if format.nil?
        datetime
      elsif format.is_a?(Proc)
        format.call(datetime)
      elsif format.is_a?(String)
        begin
          datetime.strftime(format)
        rescue NoMethodError
          raise BlueprinterError, 'Cannot format invalid DateTime object'
        end
      else
        raise BlueprinterError, 'Cannot format DateTime object with invalid formatter'
      end
    end
  end
end
