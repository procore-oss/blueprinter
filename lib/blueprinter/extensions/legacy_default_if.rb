# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # An extension to add support for V1-style `default_if` values.
    #
    # ```
    # class ApplicationBlueprint < Blueprinter::V2::Base
    #   add Blueprinter::Extensions::LegacyDefaultIf.new
    # end
    # ```
    #
    # Your Blueprints can now mix and match V1 and V2 `default_if` values.
    #
    # ```ruby
    # class MyBlueprint < ApplicationBlueprint
    #   # V2 style
    #   field :summary, default: "None", default_if: ->(ctx, val) { val.empty? }
    #   field :summary, default: "None", default_if: :empty_string?
    #
    #   # V1 style
    #   field :description, default: "None", default_if: Blueprinter::EMPTY_STRING
    #
    #   def empty_string?(ctx, val) = val.empty?
    # end
    # ```
    #
    class LegacyDefaultIf < Extension
      # @param ctx [Blueprinter::V2::Context::Init]
      # @!visibility private
      def around_blueprint_init(ctx)
        if (default_if = ctx.blueprint.options[:default_if])
          ctx.blueprint.options[:default_if] = convert_v1(default_if)
        end

        ctx.fields.each do |field|
          if (default_if = field.options[:default_if])
            field.options[:default_if] = convert_v1(default_if)
          end
        end

        yield ctx
      end

      private

      def convert_v1(cond)
        case cond
        when ::Blueprinter::EMPTY_COLLECTION, ::Blueprinter::EMPTY_HASH, ::Blueprinter::EMPTY_STRING
          ->(_ctx, value) { EmptyTypes.send(:use_default_value?, value, cond) }
        else
          cond
        end
      end
    end
  end
end
