# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      module Core
        #
        # A core extension that extracts values from objects, evaluates conditions, and applies defaults.
        #
        class Values < Extension
          # @param ctx [Blueprinter::V2::Context]
          def field_value(ctx)
            data = ctx.store[ctx.field.object_id]
            ctx.field.value_proc ? proc_value(ctx) : data[:extractor].field(ctx)
          end

          # @param ctx [Blueprinter::V2::Context]
          def object_value(ctx)
            data = ctx.store[ctx.field.object_id]
            ctx.field.value_proc ? proc_value(ctx) : data[:extractor].object(ctx)
          end

          # @param ctx [Blueprinter::V2::Context]
          def collection_value(ctx)
            data = ctx.store[ctx.field.object_id]
            ctx.field.value_proc ? proc_value(ctx) : data[:extractor].collection(ctx)
          end

          # @param ctx [Blueprinter::V2::Context]
          def prepare(ctx)
            bp_class = ctx.blueprint.class
            ref = bp_class.reflections[:default]

            ref.fields.each_value do |field|
              ctx.store[field.object_id] ||= {}
              ctx.store[field.object_id][:extractor] = ctx.instances[field.options[:extractor] || bp_class.options[:extractor] || Extractor]
            end

            ref.objects.each_value do |field|
              ctx.store[field.object_id] ||= {}
              ctx.store[field.object_id][:extractor] = ctx.instances[field.options[:extractor] || bp_class.options[:extractor] || Extractor]
            end

            ref.collections.each_value do |field|
              ctx.store[field.object_id] ||= {}
              ctx.store[field.object_id][:extractor] = ctx.instances[field.options[:extractor] || bp_class.options[:extractor] || Extractor]
            end
          end

          private

          def proc_value(ctx)
            ctx.blueprint.instance_exec(ctx, &ctx.field.value_proc)
          end
        end
      end
    end
  end
end
