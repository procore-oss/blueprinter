# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # An extension for customizing field order.
    #
    # By default, V2 serializes fields in the order they were defined. The example below
    # changes it to alphabetical order:
    #
    # ```
    # class ApplicationBlueprint < Blueprinter::V2::Base
    #   extensions << Blueprinter::Extensions::FieldOrder.new do |a, b|
    #     a.name <=> b.name
    #   end
    # end
    # ```
    #
    class FieldOrder < Extension
      # Initialize the extension with a block that sorts each field.
      # @yield [Blueprinter::V2::Fields, Blueprinter::V2::Fields] The block will be passed two fields and should
      #        return -1, 0, or 1
      def initialize(&sorter)
        @sorter = sorter
      end

      # @param ctx [Blueprinter::V2::Context::Init]
      # @!visibility private
      def around_blueprint_init(ctx)
        ctx.fields = ctx.fields.sort(&@sorter)
        yield ctx
      end
    end
  end
end
