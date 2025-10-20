# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # An optional, built-in extension for rendering JSON using the multi_json gem.
    # Requires that you have the multi_json gem installed.
    #
    # Any options you pass to the extension's constructor will be passed as options to MultiJson.dump.
    # You may also pass options through render/render_object/render_collection using the :multi_json key.
    # They will be merged with any options passed to the extension's constructor.
    #
    class MultiJson < Extension
      def initialize(options = {})
        @options = options
      end

      # @param ctx [Blueprinter::V2::Context::Result]
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
