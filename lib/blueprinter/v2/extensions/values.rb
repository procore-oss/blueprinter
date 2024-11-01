# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      class Values < Extension
        def collection?(object)
          case object
          when Array, Set then true
          else false
          end
        end

        # @param ctx [Blueprinter::V2::Context]
        def field_value(ctx)
          extractor = get_extractor ctx
          extractor.field(ctx.blueprint, ctx.field, ctx.object, ctx.options)
        end

        # @param ctx [Blueprinter::V2::Context]
        def object_value(ctx)
          extractor = get_extractor ctx
          extractor.object(ctx.blueprint, ctx.field, ctx.object, ctx.options)
        end

        # @param ctx [Blueprinter::V2::Context]
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
