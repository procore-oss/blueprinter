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
      def around_object_render(ctx, &)
        tracer.in_span('blueprinter.render', attributes: attributes(ctx), &)
      end

      # @param ctx [Blueprinter::V2::Context::Object]
      def around_collection_render(ctx, &)
        tracer.in_span('blueprinter.render', attributes: attributes(ctx), &)
      end

      # @param ctx [Blueprinter::V2::Context::Object]
      def around_object_serialization(ctx, &)
        tracer.in_span('blueprinter.object', attributes: attributes(ctx), &)
      end

      # @param ctx [Blueprinter::V2::Context::Object]
      def around_collection_serialization(ctx, &)
        tracer.in_span('blueprinter.collection', attributes: attributes(ctx), &)
      end

      # @param ext [Blueprinter::V2::Extension] Extension being run
      # @param hook [Symbol] Hook name
      def around_hook(ext, hook, &)
        attributes = { extension: ext.class.name, hook:, 'library.name' => 'Blueprinter', 'library.version' => VERSION }
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
