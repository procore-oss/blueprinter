# frozen_string_literal: true

require 'blueprinter/v2/extension'

module Blueprinter
  module V2
    module Extensions
      # An extension providing options for default values
      class DefaultValues < Extension
        # @param ctx [Blueprinter::V2::Serializer::Context]
        def field_value(ctx)
          use_default = ctx.options[:field_default_if] || ctx.field.options[:default_if] || ctx.blueprint.class.options[:field_default_if]
          return ctx.value unless ctx.value.nil? || use_default&.call(ctx)

          val = ctx.options[:field_default] || ctx.field.options[:default] || ctx.blueprint.class.options[:field_default]
          val.is_a?(Proc) ? val.call(ctx) : val
        end

        # @param ctx [Blueprinter::V2::Serializer::Context]
        def object_value(ctx)
          use_default = ctx.options[:object_default_if] || ctx.field.options[:default_if] || ctx.blueprint.class.options[:object_default_if]
          return ctx.value unless ctx.value.nil? || use_default&.call(ctx)

          val = ctx.options[:object_default] || ctx.field.options[:default] || ctx.blueprint.class.options[:object_default]
          val.is_a?(Proc) ? val.call(ctx) : val
        end

        # @param ctx [Blueprinter::V2::Serializer::Context]
        def collection_value(ctx)
          use_default = ctx.options[:collection_default_if] || ctx.field.options[:default_if] || ctx.blueprint.class.options[:collection_default_if]
          return ctx.value unless ctx.value.nil? || use_default&.call(ctx)

          val = ctx.options[:collection_default] || ctx.field.options[:default] || ctx.blueprint.class.options[:collection_default]
          val.is_a?(Proc) ? val.call(ctx) : val
        end
      end
    end
  end
end
