# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # An extension to add support for V1-style `if` and `unless` Procs.
    #
    # ```
    # class ApplicationBlueprint < Blueprinter::V2::Base
    #   add Blueprinter::Extensions::LegacyConditionals.new
    # end
    # ```
    #
    # Your Blueprints can now mix and match V1 and V2 style `if` and `unless` Procs.
    #
    # ```ruby
    # class MyBlueprint < ApplicationBlueprint
    #   # V2 style
    #   field :summary, if: ->(ctx) { ctx.object.summary.present? }
    #
    #   # V1 style
    #   field :description, if: ->(_field_name, object, _options) {
    #     object.summary.present?
    #   }
    # end
    # ```
    #
    class LegacyConditionals < Extension
      # @!visibility private
      V1_ARITY = 3

      # @param ctx [Blueprinter::V2::Context::Init]
      # @!visibility private
      def around_blueprint_init(ctx)
        # Convert blueprint if/unless options
        ctx.blueprint.options[:if] = convert_v1(ctx.blueprint.options[:if]) if ctx.blueprint.options[:if]
        ctx.blueprint.options[:unless] = convert_v1(ctx.blueprint.options[:unless]) if ctx.blueprint.options[:unless]

        # Convert field if/unless options
        ctx.fields.each do |field|
          field.options[:if] = convert_v1(field.options[:if]) if field.options[:if]
          field.options[:unless] = convert_v1(field.options[:unless]) if field.options[:unless]
        end

        yield ctx
      end

      private

      def convert_v1(cond)
        if cond.is_a?(Proc) && cond.arity == V1_ARITY
          ->(ctx) { cond.call(ctx.field.source, ctx.object, ctx.options) }
        else
          cond
        end
      end
    end
  end
end
