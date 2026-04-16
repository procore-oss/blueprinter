# frozen_string_literal: true

module Blueprinter
  module V2
    class Defaults < Extension
      def initialize(blueprint, options)
        @default = {}.compare_by_identity
        @default_if = {}.compare_by_identity
        # It's significantly faster to evaluate these options once and store them
        setup(blueprint.class, options)
      end

      def value_or_default(ctx, value)
        default_if = @default_if[ctx.field]
        return value unless value.nil? || (default_if && use_default?(default_if, value, ctx))

        case (default_value = @default[ctx.field])
        when Proc then ctx.blueprint.instance_exec(value, ctx, &default_value)
        when Symbol then ctx.blueprint.public_send(default_value, value, ctx)
        else default_value
        end
      end

      private

      def use_default?(cond, value, ctx)
        case cond
        when Proc then ctx.blueprint.instance_exec(value, ctx, &cond)
        else ctx.blueprint.public_send(cond, value, ctx)
        end
      end

      def setup(blueprint_class, options)
        ref = blueprint_class.reflections[:default]
        setup_field(blueprint_class, ref, options)
        setup_object(blueprint_class, ref, options)
        setup_collection(blueprint_class, ref, options)
      end

      def setup_field(bp_class, ref, options)
        ref.fields.each_value do |field|
          @default[field] = options[:field_default] || field.options[:default] || bp_class.options[:field_default]
          @default_if[field] =
            options[:field_default_if] || field.options[:default_if] || bp_class.options[:field_default_if]
        end
      end

      def setup_object(bp_class, ref, options)
        ref.objects.each_value do |field|
          @default[field] = options[:object_default] || field.options[:default] || bp_class.options[:object_default]
          @default_if[field] =
            options[:object_default_if] || field.options[:default_if] || bp_class.options[:object_default_if]
        end
      end

      def setup_collection(bp_class, ref, options)
        ref.collections.each_value do |field|
          @default[field] =
            options[:collection_default] || field.options[:default] || bp_class.options[:collection_default]
          @default_if[field] =
            options[:collection_default_if] || field.options[:default_if] || bp_class.options[:collection_default_if]
        end
      end
    end
  end
end
