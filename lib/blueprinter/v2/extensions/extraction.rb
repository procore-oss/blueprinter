# frozen_string_literal: true

require 'blueprinter/v2/extension'
require 'blueprinter/v2/extractor'

module Blueprinter
  module V2
    module Extensions
      # Extracts field values from objects. Should be the FIRST extension called by the serializer.
      class Extraction < Extension
        # @param ctx [Blueprinter::V2::Serializer::Context]
        def field_value(ctx)
          extractor = get_extractor ctx
          extractor.field(ctx.blueprint, ctx.field, ctx.object, ctx.options)
        end

        # @param ctx [Blueprinter::V2::Serializer::Context]
        def object_value(ctx)
          extractor = get_extractor ctx
          val = extractor.object(ctx.blueprint, ctx.field, ctx.object, ctx.options)
        end

        # @param ctx [Blueprinter::V2::Serializer::Context]
        def collection_value(ctx)
          extractor = get_extractor ctx
          extractor.collection(ctx.blueprint, ctx.field, ctx.object, ctx.options)
        end

        private

        def get_extractor(ctx)
          klass = ctx.field.options[:extractor] || ctx.blueprint.class.options[:extractor] || Extractor
          ctx.instances[klass]
        end
      end
    end
  end
end
