# frozen_string_literal: true

require 'blueprinter/v2/extension'

module Blueprinter
  module V2
    module Extensions
      # Serializes object/collection values using their Blueprint. Should be the FINAL extension called by the serializer.
      class Serialization < Extension
        # @param ctx [Blueprinter::V2::Serializer::Context]
        def object_value(ctx)
          serialize(ctx.value, ctx.field, ctx.options, ctx.instances)
        end

        # @param ctx [Blueprinter::V2::Serializer::Context]
        def collection_value(ctx)
          ctx.value.each.map do |obj|
            serialize(obj, ctx.field, ctx.options, ctx.instances)
          end
        end

        private

        def serialize(obj, field, options, instance_cache)
          case instance_cache[field.blueprint]
          when ::Blueprinter::V2::Base
            field.blueprint.serializer.call(obj, options, instance_cache)
          when ::Blueprinter::Base
            raise NotImplementedError, "V1 is not yet supported"
          else
            raise "Blueprint class '#{field.blueprint}' does not inherit from a supported base class"
          end
        end
      end
    end
  end
end
