# frozen_string_literal: true

module Blueprinter
  module V2
    class Conditionals < Extension
      def initialize(blueprint, options)
        @if = {}.compare_by_identity
        @unless = {}.compare_by_identity
        @skip_nil = {}.compare_by_identity
        @skip_empty = {}.compare_by_identity
        # It's significantly faster to evaluate these options once and store them
        setup(blueprint.class, options)
      end

      def skip?(ctx)
        if (cond = @if[ctx.field])
          result = cond.is_a?(Proc) \
            ? ctx.blueprint.instance_exec(ctx, &cond) \
            : ctx.blueprint.public_send(cond, ctx)
          return true unless result
        end

        if (cond = @unless[ctx.field])
          result = cond.is_a?(Proc) \
            ? ctx.blueprint.instance_exec(ctx, &cond) \
            : ctx.blueprint.public_send(cond, ctx)
          return true if result
        end

        false
      end

      # NOTE: ugly, non-compliant method for performance reasons
      #
      # @param ctx [Blueprinter::V2::Context::Field]
      # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Style/MultilineTernaryOperator,Style/RedundantLineContinuation
      def include?(ctx, value)
        if value.nil? && @skip_nil[ctx.field]
          return false
        elsif @skip_empty[ctx.field]
          return false if value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end

        if (cond = @if[ctx.field])
          result = cond.is_a?(Proc) \
            ? ctx.blueprint.instance_exec(value, ctx, &cond) \
            : ctx.blueprint.public_send(cond, value, ctx)
          return false unless result
        end

        if (cond = @unless[ctx.field])
          result = cond.is_a?(Proc) \
            ? ctx.blueprint.instance_exec(value, ctx, &cond) \
            : ctx.blueprint.public_send(cond, value, ctx)
          return false if result
        end

        true
      end
      # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Style/MultilineTernaryOperator,Style/RedundantLineContinuation

      private

      def setup(blueprint_class, options)
        ref = blueprint_class.reflections[:default]
        setup_field(blueprint_class, ref, options)
        setup_object(blueprint_class, ref, options)
        setup_collection(blueprint_class, ref, options)
      end

      # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      def setup_field(bp_class, ref, options)
        ref.fields.each_value do |field|
          @if[field] = options[:field_if] || field.options[:if] || bp_class.options[:field_if]
          @unless[field] = options[:field_unless] || field.options[:unless] || bp_class.options[:field_unless]
          @skip_nil[field] =
            options[:exclude_if_nil] || field.options[:exclude_if_nil] || bp_class.options[:exclude_if_nil]
          @skip_empty[field] =
            options[:exclude_if_empty] || field.options[:exclude_if_empty] || bp_class.options[:exclude_if_empty]
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

      # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      def setup_object(bp_class, ref, options)
        ref.objects.each_value do |field|
          @if[field] = options[:object_if] || field.options[:if] || bp_class.options[:object_if]
          @unless[field] = options[:object_unless] || field.options[:unless] || bp_class.options[:object_unless]
          @skip_nil[field] =
            options[:exclude_if_nil] || field.options[:exclude_if_nil] || bp_class.options[:exclude_if_nil]
          @skip_empty[field] =
            options[:exclude_if_empty] || field.options[:exclude_if_empty] || bp_class.options[:exclude_if_empty]
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

      # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      def setup_collection(bp_class, ref, options)
        ref.collections.each_value do |field|
          @if[field] = options[:collection_if] || field.options[:if] || bp_class.options[:collection_if]
          @unless[field] =
            options[:collection_unless] || field.options[:unless] || bp_class.options[:collection_unless]
          @skip_nil[field] =
            options[:exclude_if_nil] || field.options[:exclude_if_nil] || bp_class.options[:exclude_if_nil]
          @skip_empty[field] =
            options[:exclude_if_empty] || field.options[:exclude_if_empty] || bp_class.options[:exclude_if_empty]
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    end
  end
end
