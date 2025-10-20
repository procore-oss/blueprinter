# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # An optional, built-in extension for tracing blueprint renders.
    #
    class OpenTelemetry < Extension
      attr_reader :tracer_name

      def initialize(tracer_name)
        @tracer_name = tracer_name
      end

      # @param ctx [Blueprinter::V2::Context::Object]
      def around_serialize_object(ctx)
        tracer.in_span('blueprinter.object', attributes: attributes(ctx)) do
          yield ctx.object
        end
      end

      # @param ctx [Blueprinter::V2::Context::Object]
      def around_serialize_collection(ctx)
        tracer.in_span('blueprinter.collection', attributes: attributes(ctx)) do
          yield ctx.object
        end
      end

      # @param ctx [Blueprinter::V2::Context::Hook]
      def around_hook(ctx, &)
        extension = ctx.extension.class.name
        attributes = { extension:, hook: ctx.hook, 'library.name' => 'Blueprinter', 'library.version' => VERSION }
        tracer.in_span('blueprinter.extension', attributes:, &)
      end

      def hidden? = true

      private

      def tracer
        @_tracer ||= ::OpenTelemetry.tracer_provider.tracer(tracer_name)
      end

      def attributes(ctx)
        {
          'library.name' => 'Blueprinter',
          'library.version' => VERSION,
          'blueprint' => ctx.blueprint.class.to_s
        }
      end
    end
  end
end
