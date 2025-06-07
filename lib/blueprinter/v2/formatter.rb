# frozen_string_literal: true

module Blueprinter
  module V2
    # An interface for formatting values
    class Formatter
      def initialize(blueprint)
        @formatters = blueprint.formatters
      end

      # @param ctx [Blueprinter::V2::Context::Field]
      def call(ctx)
        fmt = @formatters[ctx.value.class]
        case fmt
        when nil
          ctx.value
        when Proc
          ctx.blueprint.instance_exec(ctx.value, &fmt)
        when Symbol, String
          ctx.blueprint.public_send(fmt, ctx.value)
        end
      end
    end
  end
end
