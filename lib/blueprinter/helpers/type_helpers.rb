# frozen_string_literal: true

module Blueprinter
  module TypeHelpers
    private

    def array_like?(object)
      Blueprinter.configuration.array_like_classes.any? do |klass|
        object.is_a?(klass)
      end
    end
  end
end
