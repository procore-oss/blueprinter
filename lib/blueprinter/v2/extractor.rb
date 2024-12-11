# frozen_string_literal: true

module Blueprinter
  module V2
    # The default extractor and base class for custom extractors
    class Extractor
      # @param ctx [Blueprinter::V2::Context]
      def field(ctx)
        if ctx.field.value_proc
          ctx.blueprint.instance_exec(ctx.object, ctx.options, &ctx.field.value_proc)
        elsif ctx.object.is_a? Hash
          ctx.object[ctx.field.from]
        else
          ctx.object.public_send(ctx.field.from)
        end
      end

      # @param ctx [Blueprinter::V2::Context]
      def object(ctx)
        field ctx
      end

      # @param ctx [Blueprinter::V2::Context]
      def collection(ctx)
        field ctx
      end
    end
  end
end
