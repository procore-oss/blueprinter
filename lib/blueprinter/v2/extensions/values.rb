# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      class Values < Extension
        # @param ctx [Blueprinter::V2::Context]
        def field_value(ctx)
          data = ctx.store[ctx.field.object_id]
          ctx.value = data[:extractor].field(ctx.blueprint, ctx.field, ctx.object, ctx.options)

          default_if = data[:default_if]
          return ctx.value unless ctx.value.nil? || (default_if && use_default?(default_if, ctx))

          get_default(data[:default], ctx)
        end

        # @param ctx [Blueprinter::V2::Context]
        def object_value(ctx)
          data = ctx.store[ctx.field.object_id]
          ctx.value = data[:extractor].object(ctx.blueprint, ctx.field, ctx.object, ctx.options)

          default_if = data[:default_if]
          return ctx.value unless ctx.value.nil? || (default_if && use_default?(default_if, ctx))

          get_default(data[:default], ctx)
        end

        # @param ctx [Blueprinter::V2::Context]
        def collection_value(ctx)
          data = ctx.store[ctx.field.object_id]
          ctx.value = data[:extractor].collection(ctx.blueprint, ctx.field, ctx.object, ctx.options)

          default_if = data[:default_if]
          return ctx.value unless ctx.value.nil? || (default_if && use_default?(default_if, ctx))

          get_default(data[:default], ctx)
        end

        # @param ctx [Blueprinter::V2::Context]
        def prepare(ctx)
          bp_class = ctx.blueprint.class
          ref = bp_class.reflections[:default]

          ref.fields.each_value do |field|
            ctx.store[field.object_id] ||= {}
            ctx.store[field.object_id][:extractor] = ctx.instances[field.options[:extractor] || bp_class.options[:extractor] || Extractor]
            ctx.store[field.object_id][:default_if] = ctx.options[:field_default_if] || field.options[:default_if] || bp_class.options[:field_default_if]
            ctx.store[field.object_id][:default] = ctx.options[:field_default] || field.options[:default] || bp_class.options[:field_default]
          end

          ref.objects.each_value do |field|
            ctx.store[field.object_id] ||= {}
            ctx.store[field.object_id][:extractor] = ctx.instances[field.options[:extractor] || bp_class.options[:extractor] || Extractor]
            ctx.store[field.object_id][:default_if] = ctx.options[:object_default_if] || field.options[:default_if] || bp_class.options[:object_default_if]
            ctx.store[field.object_id][:default] = ctx.options[:object_default] || field.options[:default] || bp_class.options[:object_default]
          end

          ref.collections.each_value do |field|
            ctx.store[field.object_id] ||= {}
            ctx.store[field.object_id][:extractor] = ctx.instances[field.options[:extractor] || bp_class.options[:extractor] || Extractor]
            ctx.store[field.object_id][:default_if] = ctx.options[:collection_default_if] || field.options[:default_if] || bp_class.options[:collection_default_if]
            ctx.store[field.object_id][:default] = ctx.options[:collection_default] || field.options[:default] || bp_class.options[:collection_default]
          end
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
      end
    end
  end
end
