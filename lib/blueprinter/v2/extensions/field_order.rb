# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      class FieldOrder < Extension
        def initialize(&sorter)
          @sorter = sorter
        end

        def sort_fields(fields)
          fields.sort(&@sorter)
        end
      end
    end
  end
end
