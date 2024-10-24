# frozen_string_literal: true

require 'blueprinter/v2/extension'

module Blueprinter
  module V2
    module Extensions
      # An extension providing "exclude_if_empty" options
      class ExcludeIfEmpty < Extension
        # @param ctx [Blueprinter::V2::Serializer::Context]
        def exclude_field?(ctx)
          if ctx.options[:exclude_if_empty] || ctx.field.options[:exclude_if_empty] || ctx.blueprint.class.options[:exclude_if_empty]
            ctx.value.nil? || (ctx.value.respond_to?(:empty?) && ctx.value.empty?)
          else
            false
          end
        end

        # @param ctx [Blueprinter::V2::Serializer::Context]
        def exclude_object?(...)
          exclude_field?(...)
        end

        # @param ctx [Blueprinter::V2::Serializer::Context]
        def exclude_collection?(...)
          exclude_field?(...)
        end
      end
    end
  end
end
