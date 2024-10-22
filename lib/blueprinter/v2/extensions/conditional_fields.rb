# frozen_string_literal: true

require 'blueprinter/v2/extension'

module Blueprinter
  module V2
    module Extensions
      # An extension providing "if" and "unless" options
      class ConditionalFields < Extension
        # @param ctx [Blueprinter::V2::Serializer::Context]
        def exclude_field?(ctx)
          if (cond = ctx.options[:field_if] || ctx.field.options[:if] || ctx.blueprint.class.options[:field_if])
            !ctx.blueprint.instance_exec(ctx, &cond)
          elsif (cond = ctx.options[:field_unless] || ctx.field.options[:unless] || ctx.blueprint.class.options[:field_unless])
            !!ctx.blueprint.instance_exec(ctx, &cond)
          else
            false
          end
        end

        # @param ctx [Blueprinter::V2::Serializer::Context]
        def exclude_object?(ctx)
          if (cond = ctx.options[:object_if] || ctx.field.options[:if] || ctx.blueprint.class.options[:object_if])
            !ctx.blueprint.instance_exec(ctx, &cond)
          elsif (cond = ctx.options[:object_unless] || ctx.field.options[:unless] || ctx.blueprint.class.options[:object_unless])
            !!ctx.blueprint.instance_exec(ctx, &cond)
          else
            false
          end
        end

        # @param ctx [Blueprinter::V2::Serializer::Context]
        def exclude_collection?(ctx)
          if (cond = ctx.options[:collection_if] || ctx.field.options[:if] || ctx.blueprint.class.options[:collection_if])
            !ctx.blueprint.instance_exec(ctx, &cond)
          elsif (cond = ctx.options[:collection_unless] || ctx.field.options[:unless] || ctx.blueprint.class.options[:collection_unless])
            !!ctx.blueprint.instance_exec(ctx, &cond)
          else
            false
          end
        end
      end
    end
  end
end
