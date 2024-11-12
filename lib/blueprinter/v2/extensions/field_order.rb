# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      class FieldOrder < Extension
        def initialize(&sorter)
          @sorter = sorter
        end

        def blueprint_fields(ctx)
          ctx.blueprint.class.reflections[:default].ordered.sort(&@sorter)
        end
      end
    end
  end
end
