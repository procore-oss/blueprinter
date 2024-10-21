# frozen_string_literal: true

module Blueprinter
  module V2
    class Extension
      class << self
        attr_accessor :formatters
      end

      def self.inherited(ext)
        ext.formatters = {}
      end

      #
      # Add a formatter for instances of the given class.
      #
      # Example:
      #   format(Time) { |time, options| time.iso8601 }
      #   format Date, :date_str
      #
      #   def date_str(date, options)
      #     date.iso8601
      #   end
      #
      # @param klass [Class] The class of objects to format
      # @param formatter_method [Symbol] Name of a public instance method to call for formatting
      # @yield Do formatting in the block instead
      #
      def self.format(klass, formatter_method = nil, &formatter_block)
        formatters[klass] = formatter_method || formatter_block
      end
    end
  end
end
