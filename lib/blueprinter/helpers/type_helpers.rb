# frozen_string_literal: true

module Blueprinter
  module TypeHelpers
    private

    def array_like?(object)
      object.is_a?(Enumerable) && !object.is_a?(Hash)
    end
  end
end
