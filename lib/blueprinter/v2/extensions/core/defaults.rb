# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      module Core
        #
        # A core extension that applies defaults values.
        #
        class Defaults < Extension
          # @param ctx [Blueprinter::V2::Context::Field]
          def field_value(ctx)
            config = ctx.store[ctx.field.object_id]
            default_if = config[:default_if]
            return ctx.value unless ctx.value.nil? || (default_if && use_default?(default_if, ctx))

            get_default(config[:default], ctx)
          end

          # @param ctx [Blueprinter::V2::Context::Field]
          def object_value(ctx)
            config = ctx.store[ctx.field.object_id]
            default_if = config[:default_if]
            return ctx.value unless ctx.value.nil? || (default_if && use_default?(default_if, ctx))

            get_default(config[:default], ctx)
          end

          # @param ctx [Blueprinter::V2::Context::Field]
          def collection_value(ctx)
            config = ctx.store[ctx.field.object_id]
            default_if = config[:default_if]
            return ctx.value unless ctx.value.nil? || (default_if && use_default?(default_if, ctx))

            get_default(config[:default], ctx)
          end

          # It's significantly faster to evaluate these options once and store them in the context
          # @param ctx [Blueprinter::V2::Context::Render]
          def prepare(ctx)
            ref = ctx.blueprint.class.reflections[:default]
            ref.fields.each_value { |field| prepare_field ctx, field }
            ref.objects.each_value { |object| prepare_object ctx, object }
            ref.collections.each_value { |collection| prepare_collection ctx, collection }
          end

          def hidden? = true

          private

          def prepare_field(ctx, field)
            bp_class = ctx.blueprint.class
            config = (ctx.store[field.object_id] ||= {})
            config[:default] = ctx.options[:field_default] || field.options[:default] || bp_class.options[:field_default]
            config[:default_if] =
              ctx.options[:field_default_if] || field.options[:default_if] || bp_class.options[:field_default_if]
          end

          def prepare_object(ctx, field)
            bp_class = ctx.blueprint.class
            config = (ctx.store[field.object_id] ||= {})
            config[:default] = ctx.options[:object_default] || field.options[:default] || bp_class.options[:object_default]
            config[:default_if] =
              ctx.options[:object_default_if] || field.options[:default_if] || bp_class.options[:object_default_if]
          end

          def prepare_collection(ctx, field)
            bp_class = ctx.blueprint.class
            config = (ctx.store[field.object_id] ||= {})
            config[:default] =
              ctx.options[:collection_default] || field.options[:default] || bp_class.options[:collection_default]
            config[:default_if] =
              ctx.options[:collection_default_if] || field.options[:default_if] || bp_class.options[:collection_default_if]
          end

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
        end
      end
    end
  end
end
