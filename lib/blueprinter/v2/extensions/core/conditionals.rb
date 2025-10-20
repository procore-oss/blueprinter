# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      module Core
        #
        # A core extension that skips fields based on given options.
        #
        class Conditionals < Extension
          def initialize
            @if = {}.compare_by_identity
            @unless = {}.compare_by_identity
            @ex_if_nil = {}.compare_by_identity
            @ex_if_empty = {}.compare_by_identity
          end

          # @param ctx [Blueprinter::V2::Context::Field]
          # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
          def around_field_value(ctx)
            value = yield
            if value.nil? && @ex_if_nil[ctx.field]
              return skip
            elsif @ex_if_empty[ctx.field]
              return skip if value.nil? || (value.respond_to?(:empty?) && value.empty?)
            end

            if (cond = @if[ctx.field])
              result = cond.is_a?(Proc) ? ctx.blueprint.instance_exec(value, ctx, &cond) : ctx.blueprint.public_send(cond, value, ctx)
              return skip unless result
            end
            if (cond = @unless[ctx.field])
              result = cond.is_a?(Proc) ? ctx.blueprint.instance_exec(value, ctx, &cond) : ctx.blueprint.public_send(cond, value, ctx)
              return skip if result
            end
            value
          end
          # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

          alias around_object_value around_field_value
          alias around_collection_value around_field_value

          # It's significantly faster to evaluate these options once and store them
          # @param ctx [Blueprinter::V2::Context::Render]
          def blueprint_setup(ctx)
            ref = ctx.blueprint.class.reflections[:default]
            setup_fields(ctx, ref)
            setup_objects(ctx, ref)
            setup_collections(ctx, ref)
          end

          def hidden? = true

          private

          # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
          def setup_fields(ctx, ref)
            bp_class = ctx.blueprint.class
            ref.fields.each_value do |field|
              @if[field] = ctx.options[:field_if] || field.options[:if] || bp_class.options[:field_if]
              @unless[field] = ctx.options[:field_unless] || field.options[:unless] || bp_class.options[:field_unless]
              @ex_if_nil[field] =
                ctx.options[:exclude_if_nil] || field.options[:exclude_if_nil] || bp_class.options[:exclude_if_nil]
              @ex_if_empty[field] =
                ctx.options[:exclude_if_empty] || field.options[:exclude_if_empty] || bp_class.options[:exclude_if_empty]
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

          # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
          def setup_objects(ctx, ref)
            bp_class = ctx.blueprint.class
            ref.objects.each_value do |field|
              @if[field] = ctx.options[:object_if] || field.options[:if] || bp_class.options[:object_if]
              @unless[field] = ctx.options[:object_unless] || field.options[:unless] || bp_class.options[:object_unless]
              @ex_if_nil[field] =
                ctx.options[:exclude_if_nil] || field.options[:exclude_if_nil] || bp_class.options[:exclude_if_nil]
              @ex_if_empty[field] =
                ctx.options[:exclude_if_empty] || field.options[:exclude_if_empty] || bp_class.options[:exclude_if_empty]
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

          # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
          def setup_collections(ctx, ref)
            bp_class = ctx.blueprint.class
            ref.collections.each_value do |field|
              @if[field] = ctx.options[:collection_if] || field.options[:if] || bp_class.options[:collection_if]
              @unless[field] =
                ctx.options[:collection_unless] || field.options[:unless] || bp_class.options[:collection_unless]
              @ex_if_nil[field] =
                ctx.options[:exclude_if_nil] || field.options[:exclude_if_nil] || bp_class.options[:exclude_if_nil]
              @ex_if_empty[field] =
                ctx.options[:exclude_if_empty] || field.options[:exclude_if_empty] || bp_class.options[:exclude_if_empty]
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        end
      end
    end
  end
end
