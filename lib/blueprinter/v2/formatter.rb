# frozen_string_literal: true

module Blueprinter
  module V2
    # An interface for formatting values
    class Formatter
      # @return [Array<Blueprinter::V2::DSL::Nodes::Format>]
      def initialize(formatters)
        @formatters = formatters
      end

      def any? = @formatters.any?

      # @param blueprint [Blueprinter::V2::Base] Blueprint instance
      # @param value
      def call(blueprint, value)
        fmt = @formatters[value.class]
        case fmt
        when nil
          value
        when Proc
          blueprint.instance_exec(value, &fmt)
        when Symbol, String
          blueprint.public_send(fmt, value)
        end
      end
    end
  end
end
