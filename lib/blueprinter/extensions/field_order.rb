# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # An optional, built-in extension for changing the default field order.
    #
    # Example of alphabetical order:
    #
    #   class MyBlueprint < ApplicationBlueprint
    #     extensions << Blueprinter::Extensions::FieldOrder.new { |a, b| a.name <=> b.name }
    #   end
    #
    class FieldOrder < Extension
      def initialize(&sorter)
        @sorter = sorter
      end

      # @param ctx [Blueprinter::V2::Context::Render]
      # @return [Array<Blueprinter::V2::Fields::*>]
      def blueprint_fields(ctx)
        ctx.fields.sort(&@sorter)
      end
    end
  end
end
