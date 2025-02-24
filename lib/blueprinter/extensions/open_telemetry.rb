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

      def around_render(ctx)
        tracer.in_span('blueprinter.render', attributes: attributes(ctx)) do
          yield
        end
      end

      def around_object_serialization(ctx)
        tracer.in_span('blueprinter.object', attributes: attributes(ctx)) do
          yield
        end
      end

      def around_collection_serialization(ctx)
        tracer.in_span('blueprinter.collection', attributes: attributes(ctx)) do
          yield
        end
      end

      def around_hook(ext, hook)
        attributes = { extension: ext.class.name, hook:, 'library.name' => 'Blueprinter', 'library.version' => VERSION }
        tracer.in_span('blueprinter.extension', attributes:) do
          yield
        end
      end

      def hidden? = true

      private

      def tracer
        @tracer ||= ::OpenTelemetry.tracer_provider.tracer(tracer_name)
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
