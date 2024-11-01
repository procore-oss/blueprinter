# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      class Exclusions < Extension
        # @param ctx [Blueprinter::V2::Context]
        def exclude_field?(ctx)
          return true if exclude_if_nil_or_empty? ctx
          if (cond = ctx.options[:field_if] || ctx.field.options[:if] || ctx.blueprint.class.options[:field_if])
            result = cond.is_a?(Proc) ? ctx.blueprint.instance_exec(ctx, &cond) : ctx.blueprint.public_send(cond, ctx)
            return true if !result
          end
          if (cond = ctx.options[:field_unless] || ctx.field.options[:unless] || ctx.blueprint.class.options[:field_unless])
            result = cond.is_a?(Proc) ? ctx.blueprint.instance_exec(ctx, &cond) : ctx.blueprint.public_send(cond, ctx)
            return true if result
          end
          false
        end

        # @param ctx [Blueprinter::V2::Context]
        def exclude_object?(ctx)
          return true if exclude_if_nil_or_empty? ctx
          if (cond = ctx.options[:object_if] || ctx.field.options[:if] || ctx.blueprint.class.options[:object_if])
            result = cond.is_a?(Proc) ? ctx.blueprint.instance_exec(ctx, &cond) : ctx.blueprint.public_send(cond, ctx)
            return true if !result
          end
          if (cond = ctx.options[:object_unless] || ctx.field.options[:unless] || ctx.blueprint.class.options[:object_unless])
            result = cond.is_a?(Proc) ? ctx.blueprint.instance_exec(ctx, &cond) : ctx.blueprint.public_send(cond, ctx)
            return true if result
          end
          false
        end

        # @param ctx [Blueprinter::V2::Context]
        def exclude_collection?(ctx)
          return true if exclude_if_nil_or_empty? ctx
          if (cond = ctx.options[:collection_if] || ctx.field.options[:if] || ctx.blueprint.class.options[:collection_if])
            result = cond.is_a?(Proc) ? ctx.blueprint.instance_exec(ctx, &cond) : ctx.blueprint.public_send(cond, ctx)
            return true if !result
          end
          if (cond = ctx.options[:collection_unless] || ctx.field.options[:unless] || ctx.blueprint.class.options[:collection_unless])
            result = cond.is_a?(Proc) ? ctx.blueprint.instance_exec(ctx, &cond) : ctx.blueprint.public_send(cond, ctx)
            return true if result
          end
          false
        end

        private

        def exclude_if_nil_or_empty?(ctx)
          if ctx.value.nil? && (ctx.options[:exclude_if_nil] || ctx.field.options[:exclude_if_nil] || ctx.blueprint.class.options[:exclude_if_nil])
            return true
          elsif ctx.options[:exclude_if_empty] || ctx.field.options[:exclude_if_empty] || ctx.blueprint.class.options[:exclude_if_empty]
            return true if ctx.value.nil? || (ctx.value.respond_to?(:empty?) && ctx.value.empty?)
          end
          false
        end
      end
    end
  end
end
