# frozen_string_literal: true

require 'blueprinter/v2/extension'

module Blueprinter
  module V2
    module Extensions
      # An extension providing "exclude_if_nil" options
      class ExcludeIfNil < Extension
        # @param ctx [Blueprinter::V2::Serializer::Context]
        def exclude_field?(ctx)
          ctx.value.nil? && !!(ctx.options[:exclude_if_nil] || ctx.field.options[:exclude_if_nil] || ctx.blueprint.class.options[:exclude_if_nil])
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
