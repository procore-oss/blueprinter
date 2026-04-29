# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # An extension for using `MultiJson` for serializing JSON. Requires that you have the `multi_json` gem installed
    # and configured to use the serializer of your choice.
    #
    # ```
    # class ApplicationBlueprint < Blueprinter::V2::Base
    #   extensions << Blueprinter::Extensions::MultiJson.new
    # end
    # ```
    #
    # Any options you pass to the extension's constructor will be passed as options to `MultiJson.dump`.
    #
    #   Blueprinter::Extensions::MultiJson.new({ pretty: true })
    #
    # You may also pass options through `render/render_object/render_collection` using the `:multi_json` key.
    # They will be merged with any options passed to the extension's constructor.
    #
    #   WidgetBlueprint.render(widget, { multi_json: { pretty: true } })
    #
    class MultiJson < Extension
      # Initialize the extension.
      #
      # @param options [Hash] Any options you pass here will be passed through to `MultiJson.dump`
      def initialize(options = {})
        @options = options
      end

      # @param ctx [Blueprinter::V2::Context::Result]
      # @!visibility private
      def around_result(ctx)
        case ctx.format
        when :json
          ctx.format = :hash
          result = yield ctx
          opts = ctx.options[:multi_json] ? @options.merge(ctx.options[:multi_json]) : @options
          final ::MultiJson.dump(result, opts)
        else
          yield ctx
        end
      end
    end
  end
end
