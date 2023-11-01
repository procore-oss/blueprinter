# frozen_string_literal: true

module Blueprinter
  module TypeHelpers
    private

    # Returns true if object can act as an Array. When `array_like_classes` are configured, we will default to that list
    # only. Otherwise, we will check if object's class includes Enumerable.
    def array_like?(object)
      return false if object.is_a?(Hash)

      if Blueprinter.configuration.array_like_classes.empty?
        object.class.include?(Enumerable)
      else
        Blueprinter.configuration.array_like_classes.any? do |klass|
          object.is_a?(klass)
        end
      end
    end
  end
end
