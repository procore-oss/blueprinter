# frozen_string_literal: true

module Blueprinter
  module V2
    module FieldSerializers
      class Base
        attr_reader :field

        def initialize(field, serializer)
          @field = field
          @instances = serializer.instances
          @hooks = serializer.hooks
          @extractor = serializer.extractor
          @defaults = serializer.defaults
          @conditionals = serializer.conditionals
          @formatter = serializer.formatter
          find_used_hooks!
        end
      end
    end
  end
end
