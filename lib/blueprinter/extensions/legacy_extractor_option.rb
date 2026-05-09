# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # Support for Legacy/V1's `extractor` option.
    #
    # NOTE: In the long term it's recommended to refactor your extractor into a V2 extension using the `around_field_value`,
    # `around_object_value`, and `around_collection_value` hooks. See {Blueprinter::Extension} for details.
    #
    # ```
    # class ApplicationBlueprint < Blueprinter::V2::Base
    #   extensions << Blueprinter::Extensions::LegacyExtractorOption.new
    # end
    # ```
    #
    # Your fields (and Blueprint options) can now use V1-style extractors without modification.
    #
    # ```ruby
    # class MyBlueprint < ApplicationBlueprint
    #   # set a global extractor for this blueprint
    #   options[:extractor] = MyDefaultExtractor
    #
    #   field :name
    #   # set on individual fields
    #   field :weird_object, extractor: MyWeirdExtractor
    # end
    # ```
    #
    class LegacyExtractorOption < Extension
      # @!visibility private
      def extract(ctx)
        extractor_class = ctx.field.options[:extractor] || ctx.blueprint.options[:extractor]
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
