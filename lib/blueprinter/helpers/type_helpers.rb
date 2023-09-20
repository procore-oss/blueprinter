module Blueprinter
  module TypeHelpers
    private

    def array_like?(object)
      object.is_a?(Array) || object.respond_to?(:to_ary)
    end
  end
end
