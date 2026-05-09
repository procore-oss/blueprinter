# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # An extension for outputting serialization telemetry using `OpenTelemetry`.
    #
    # It will generate spans for each V2 Blueprint that's serialized, noting if it was for a single object
    # or a collection. It will also trace other extension's hooks.
    #
    # ```
    # class ApplicationBlueprint < Blueprinter::V2::Base
    #   extensions << Blueprinter::Extensions::OpenTelemetry.new("my-tracer")
    # end
    # ```
    #
    # The span names it outputs are:
    #
    # - `blueprinter.object` (includes Blueprint/view)
    # - `blueprinter.collection` (includes Blueprint/view)
    # - `blueprinter.extension` (includes Blueprint/view, extension, and hook)
    #
    class OpenTelemetry < Extension
      # @!visibility private
      attr_reader :tracer_name

      # Initialize the extension with the tracer's name.
      #
      # @param tracer_name [String]
      def initialize(tracer_name)
        @tracer_name = tracer_name
      end

      # @param ctx [Blueprinter::V2::Context::Object]
      # @!visibility private
      def around_serialize_object(ctx)
        tracer.in_span('blueprinter.object', attributes: attributes(ctx)) do
          yield ctx
        end
      end

      # @param ctx [Blueprinter::V2::Context::Object]
      # @!visibility private
      def around_serialize_collection(ctx)
        tracer.in_span('blueprinter.collection', attributes: attributes(ctx)) do
          yield ctx
        end
      end

      # @param ctx [Blueprinter::V2::Context::Hook]
      # @!visibility private
      def around_hook(ctx)
        extension = ctx.extension.class.name
        attributes = { extension:, hook: ctx.hook, 'library.name' => 'Blueprinter', 'library.version' => VERSION }
        tracer.in_span('blueprinter.extension', attributes:) { |_| yield }
      end

      # @!visibility private
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
