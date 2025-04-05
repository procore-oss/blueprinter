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

            default_if = config[:default_if]
            return ctx.value unless ctx.value.nil? || (default_if && use_default?(default_if, ctx))

            get_default(config[:default], ctx)
          end

          # @param ctx [Blueprinter::V2::Context::Field]
          def object_value(ctx)
            config = ctx.store[ctx.field.object_id]
            ctx.value = ctx.field.value_proc ? proc_value(ctx) : config[:extractor].object(ctx)

            default_if = config[:default_if]
            return ctx.value unless ctx.value.nil? || (default_if && use_default?(default_if, ctx))

            get_default(config[:default], ctx)
          end

          # @param ctx [Blueprinter::V2::Context::Field]
          def collection_value(ctx)
            config = ctx.store[ctx.field.object_id]
            ctx.value = ctx.field.value_proc ? proc_value(ctx) : config[:extractor].collection(ctx)

            default_if = config[:default_if]
            return ctx.value unless ctx.value.nil? || (default_if && use_default?(default_if, ctx))

            get_default(config[:default], ctx)
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

          # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
          def prepare_fields(ctx, ref)
            bp_class = ctx.blueprint.class
            ref.fields.each_value do |field|
              config = (ctx.store[field.object_id] ||= {})
              config[:extractor] = ctx.instances[field.options[:extractor] || bp_class.options[:extractor] || Extractor]
              config[:default] = ctx.options[:field_default] || field.options[:default] || bp_class.options[:field_default]
              config[:default_if] =
                ctx.options[:field_default_if] || field.options[:default_if] || bp_class.options[:field_default_if]
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

          # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
          def prepare_objects(ctx, ref)
            bp_class = ctx.blueprint.class
            ref.objects.each_value do |field|
              config = (ctx.store[field.object_id] ||= {})
              config[:extractor] = ctx.instances[field.options[:extractor] || bp_class.options[:extractor] || Extractor]
              config[:default] = ctx.options[:object_default] || field.options[:default] || bp_class.options[:object_default]
              config[:default_if] =
                ctx.options[:object_default_if] || field.options[:default_if] || bp_class.options[:object_default_if]
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

          # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
          def prepare_collections(ctx, ref)
            bp_class = ctx.blueprint.class
            ref.collections.each_value do |field|
              config = (ctx.store[field.object_id] ||= {})
              config[:extractor] = ctx.instances[field.options[:extractor] || bp_class.options[:extractor] || Extractor]
              config[:default] =
                ctx.options[:collection_default] || field.options[:default] || bp_class.options[:collection_default]
              config[:default_if] =
                ctx.options[:collection_default_if] || field.options[:default_if] || bp_class.options[:collection_default_if]
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

          # @param ctx [Blueprinter::V2::Context::Field]
          def proc_value(ctx)
            ctx.blueprint.instance_exec(ctx, &ctx.field.value_proc)
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
