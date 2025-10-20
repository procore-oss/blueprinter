# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      module Core
        #
        # A core extension that applies defaults values.
        #
        class Defaults < Extension
          def initialize = @config = {}.compare_by_identity

          # @param ctx [Blueprinter::V2::Context::Field]
          def around_field_value(ctx)
            value = yield
            config = @config[ctx.field]
            default_if = config[:default_if]
            return value unless value.nil? || (default_if && use_default?(default_if, value, ctx))

            get_default(config[:default], value, ctx)
          end

          # @param ctx [Blueprinter::V2::Context::Field]
          def around_object_value(ctx)
            value = yield
            config = @config[ctx.field]
            default_if = config[:default_if]
            return value unless value.nil? || (default_if && use_default?(default_if, value, ctx))

            get_default(config[:default], value, ctx)
          end

          # @param ctx [Blueprinter::V2::Context::Field]
          def around_collection_value(ctx)
            value = yield
            config = @config[ctx.field]
            default_if = config[:default_if]
            return value unless value.nil? || (default_if && use_default?(default_if, value, ctx))

            get_default(config[:default], value, ctx)
          end

          # It's significantly faster to evaluate these options once and store them in the context
          # @param ctx [Blueprinter::V2::Context::Render]
          def blueprint_setup(ctx)
            ref = ctx.blueprint.class.reflections[:default]
            ref.fields.each_value { |field| setup_field ctx, field }
            ref.objects.each_value { |object| setup_object ctx, object }
            ref.collections.each_value { |collection| setup_collection ctx, collection }
          end

          def hidden? = true

          private

          def setup_field(ctx, field)
            bp_class = ctx.blueprint.class
            config = (@config[field] ||= {})
            config[:default] = ctx.options[:field_default] || field.options[:default] || bp_class.options[:field_default]
            config[:default_if] =
              ctx.options[:field_default_if] || field.options[:default_if] || bp_class.options[:field_default_if]
          end

          def setup_object(ctx, field)
            bp_class = ctx.blueprint.class
            config = (@config[field] ||= {})
            config[:default] = ctx.options[:object_default] || field.options[:default] || bp_class.options[:object_default]
            config[:default_if] =
              ctx.options[:object_default_if] || field.options[:default_if] || bp_class.options[:object_default_if]
          end

          def setup_collection(ctx, field)
            bp_class = ctx.blueprint.class
            config = (@config[field] ||= {})
            config[:default] =
              ctx.options[:collection_default] || field.options[:default] || bp_class.options[:collection_default]
            config[:default_if] =
              ctx.options[:collection_default_if] || field.options[:default_if] || bp_class.options[:collection_default_if]
          end

          def get_default(default_value, value, ctx)
            case default_value
            when Proc then ctx.blueprint.instance_exec(value, ctx, &default_value)
            when Symbol then ctx.blueprint.public_send(default_value, value, ctx)
            else default_value
            end
          end

          def use_default?(cond, value, ctx)
            case cond
            when Proc then ctx.blueprint.instance_exec(value, ctx, &cond)
            else ctx.blueprint.public_send(cond, value, ctx)
            end
          end
        end
      end
    end
  end
end
