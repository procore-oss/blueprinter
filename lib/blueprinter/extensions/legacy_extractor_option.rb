# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # Support for Legacy/V1's `extractor` option.
    #
    class LegacyExtractorOption < Extension
      # @!visibility private
      def extract(ctx)
        extractor_class = ctx.field.options[:extractor] || ctx.blueprint_options[:extractor]
        return yield ctx if extractor_class.nil?

        extractor = ctx.store[extractor_class.object_id] ||= extractor_class.new
        extractor.extract(ctx.field.source, ctx.object, ctx.options, ctx.field.options)
      end

      # @!visibility private
      alias around_field_value extract

      # @!visibility private
      alias around_object_value extract

      # @!visibility private
      alias around_collection_value extract
    end
  end
end
