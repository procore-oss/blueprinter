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
          value = extractor.field(ctx.blueprint, ctx.field, ctx.object, ctx.options)

          default_if = ctx.options[:field_default_if] || ctx.field.options[:default_if] || ctx.blueprint.class.options[:field_default_if]
          return value unless value.nil? || (default_if && use_default?(default_if, ctx))

          default = ctx.options[:field_default] || ctx.field.options[:default] || ctx.blueprint.class.options[:field_default]
          get_default(default, ctx)
        end

        # @param ctx [Blueprinter::V2::Context]
        def object_value(ctx)
          extractor = get_extractor ctx
          value = extractor.object(ctx.blueprint, ctx.field, ctx.object, ctx.options)

          default_if = ctx.options[:object_default_if] || ctx.field.options[:default_if] || ctx.blueprint.class.options[:object_default_if]
          return value unless value.nil? || (default_if && use_default?(default_if, ctx))

          default = ctx.options[:object_default] || ctx.field.options[:default] || ctx.blueprint.class.options[:object_default]
          get_default(default, ctx)
        end

        # @param ctx [Blueprinter::V2::Context]
        def collection_value(ctx)
          extractor = get_extractor ctx
          value = extractor.collection(ctx.blueprint, ctx.field, ctx.object, ctx.options)

          default_if = ctx.options[:collection_default_if] || ctx.field.options[:default_if] || ctx.blueprint.class.options[:collection_default_if]
          return value unless value.nil? || (default_if && use_default?(default_if, ctx))

          default = ctx.options[:collection_default] || ctx.field.options[:default] || ctx.blueprint.class.options[:collection_default]
          get_default(default, ctx)
        end

        private

        def get_default(value, ctx)
          case value
          when Proc then ctx.blueprint.instance_exec(ctx, &value)
          when Symbol then ctx.blueprint.public_send(value, ctx)
          else value
          end
        end

        def use_default?(cond, ctx)
          case cond
          when Proc then ctx.blueprint.instance_exec(ctx, &cond)
          else ctx.blueprint.public_send(cond, ctx)
          end
        end

        def get_extractor(ctx)
          klass = ctx.field.options[:extractor] || ctx.blueprint.class.options[:extractor] || Extractor
          ctx.instances[klass]
        end
      end
    end
  end
end
