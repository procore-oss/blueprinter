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

      def json(ctx)
        opts = ctx.options[:multi_json] ? @options.merge(ctx.options[:multi_json]) : @options
        ::MultiJson.dump(ctx.value, opts)
      end
    end
  end
end
