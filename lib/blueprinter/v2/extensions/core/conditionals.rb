# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      module Core
        class Conditionals < Extension
          # @param ctx [Blueprinter::V2::Context::Field]
          # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
          def exclude_field?(ctx)
            config = ctx.store[ctx.field.object_id]
            if ctx.value.nil? && config[:exclude_if_nil]
              return true
            elsif config[:exclude_if_empty]
              return true if ctx.value.nil? || (ctx.value.respond_to?(:empty?) && ctx.value.empty?)
            end

            if (cond = config[:if])
              result = cond.is_a?(Proc) ? ctx.blueprint.instance_exec(ctx, &cond) : ctx.blueprint.public_send(cond, ctx)
              return true unless result
            end
            if (cond = config[:unless])
              result = cond.is_a?(Proc) ? ctx.blueprint.instance_exec(ctx, &cond) : ctx.blueprint.public_send(cond, ctx)
              return true if result
            end
            false
          end
          # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

          # @param ctx [Blueprinter::V2::Context::Field]
          def exclude_object?(ctx)
            exclude_field? ctx
          end

          # @param ctx [Blueprinter::V2::Context::Field]
          def exclude_collection?(ctx)
            exclude_field? ctx
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
              ctx.store[field.object_id] ||= {}
              ctx.store[field.object_id][:if] = ctx.options[:field_if] || field.options[:if] || bp_class.options[:field_if]
              ctx.store[field.object_id][:unless] =
                ctx.options[:field_unless] || field.options[:unless] || bp_class.options[:field_unless]
              ctx.store[field.object_id][:exclude_if_nil] =
                ctx.options[:exclude_if_nil] || field.options[:exclude_if_nil] || bp_class.options[:exclude_if_nil]
              ctx.store[field.object_id][:exclude_if_empty] =
                ctx.options[:exclude_if_empty] || field.options[:exclude_if_empty] || bp_class.options[:exclude_if_empty]
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

          # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
          def prepare_objects(ctx, ref)
            bp_class = ctx.blueprint.class
            ref.objects.each_value do |field|
              ctx.store[field.object_id] ||= {}
              ctx.store[field.object_id][:if] = ctx.options[:object_if] || field.options[:if] || bp_class.options[:object_if]
              ctx.store[field.object_id][:unless] =
                ctx.options[:object_unless] || field.options[:unless] || bp_class.options[:object_unless]
              ctx.store[field.object_id][:exclude_if_nil] =
                ctx.options[:exclude_if_nil] || field.options[:exclude_if_nil] || bp_class.options[:exclude_if_nil]
              ctx.store[field.object_id][:exclude_if_empty] =
                ctx.options[:exclude_if_empty] || field.options[:exclude_if_empty] || bp_class.options[:exclude_if_empty]
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

          # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
          def prepare_collections(ctx, ref)
            bp_class = ctx.blueprint.class
            ref.collections.each_value do |field|
              ctx.store[field.object_id] ||= {}
              ctx.store[field.object_id][:if] =
                ctx.options[:collection_if] || field.options[:if] || bp_class.options[:collection_if]
              ctx.store[field.object_id][:unless] =
                ctx.options[:collection_unless] || field.options[:unless] || bp_class.options[:collection_unless]
              ctx.store[field.object_id][:exclude_if_nil] =
                ctx.options[:exclude_if_nil] || field.options[:exclude_if_nil] || bp_class.options[:exclude_if_nil]
              ctx.store[field.object_id][:exclude_if_empty] =
                ctx.options[:exclude_if_empty] || field.options[:exclude_if_empty] || bp_class.options[:exclude_if_empty]
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        end
      end
    end
  end
end
