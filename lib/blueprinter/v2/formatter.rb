# frozen_string_literal: true

module Blueprinter
  module V2
    # An interface for formatting values
    class Formatter
      def initialize(blueprint)
        @formatters = blueprint.formatters
      end

      # @param value
      # @param ctx [Blueprinter::V2::Context::Field]
      def call(value, ctx)
        fmt = @formatters[value.class]
        case fmt
        when nil
          value
        when Proc
          ctx.blueprint.instance_exec(value, &fmt)
        when Symbol, String
          ctx.blueprint.public_send(fmt, value)
        end
      end
    end
  end
end
