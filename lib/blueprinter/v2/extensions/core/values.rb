# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      module Core
        #
        # A core extension that extracts values from objects, evaluates conditions, and applies defaults.
        #
        class Values < Extension
          # @param ctx [Blueprinter::V2::Context::Field]
          def field_value(ctx)
            config = ctx.store[ctx.field.object_id]
            ctx.value = ctx.field.value_proc ? proc_value(ctx) : config[:extractor].field(ctx)
          end

          # @param ctx [Blueprinter::V2::Context::Field]
          def object_value(ctx)
            config = ctx.store[ctx.field.object_id]
            ctx.value = ctx.field.value_proc ? proc_value(ctx) : config[:extractor].object(ctx)
          end

          # @param ctx [Blueprinter::V2::Context::Field]
          def collection_value(ctx)
            config = ctx.store[ctx.field.object_id]
            ctx.value = ctx.field.value_proc ? proc_value(ctx) : config[:extractor].collection(ctx)
          end

          # It's significantly faster to evaluate these options once and store them in the context
          # @param ctx [Blueprinter::V2::Context::Render]
          def prepare(ctx)
            ref = ctx.blueprint.class.reflections[:default]
            prepare_fields(ctx, ref)
            prepare_objects(ctx, ref)
            prepare_collections(ctx, ref)
          end

          def hidden? = true

          private

          def prepare_fields(ctx, ref)
            bp_class = ctx.blueprint.class
            ref.fields.each_value do |field|
              ctx.store[field.object_id] ||= {}
              ctx.store[field.object_id][:extractor] =
                ctx.instances[field.options[:extractor] || bp_class.options[:extractor] || Extractor]
            end
          end

          def prepare_objects(ctx, ref)
            bp_class = ctx.blueprint.class
            ref.objects.each_value do |field|
              ctx.store[field.object_id] ||= {}
              ctx.store[field.object_id][:extractor] =
                ctx.instances[field.options[:extractor] || bp_class.options[:extractor] || Extractor]
            end
          end

          def prepare_collections(ctx, ref)
            bp_class = ctx.blueprint.class
            ref.collections.each_value do |field|
              ctx.store[field.object_id] ||= {}
              ctx.store[field.object_id][:extractor] =
                ctx.instances[field.options[:extractor] || bp_class.options[:extractor] || Extractor]
            end
          end

          # @param ctx [Blueprinter::V2::Context::Field]
          def proc_value(ctx)
            ctx.blueprint.instance_exec(ctx, &ctx.field.value_proc)
          end
        end
      end
    end
  end
end
