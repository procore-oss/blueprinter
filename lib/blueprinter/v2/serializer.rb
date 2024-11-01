# frozen_string_literal: true

require 'blueprinter/hooks'
require 'blueprinter/v2/formatter'

module Blueprinter
  module V2
    class Serializer
      # Core extensions that must run at the start of serialization
      CORE_START = [
        Extensions::Values
      ].freeze

      # Core extensions that must run at the end of serialization
      CORE_FINISH = [].freeze

      attr_reader :blueprint, :formatter, :hooks

      def initialize(blueprint)
        @hooks = Hooks.new(CORE_START.map(&:new) + blueprint.extensions + CORE_FINISH.map(&:new))
        @formatter = Formatter.new(blueprint)
        @blueprint = blueprint
      end

      def call(object, options, instances)
        context = Context.new(instances[blueprint], nil, nil, object, options, instances)
        hooks.reduce_into(:blueprint_input, context, :object)

        result = blueprint.reflections[:default].sorted.each_with_object({}) do |field, acc|
          context.field = field
          context.value = nil

          case field
          when Field
            hooks.reduce_into(:field_value, context, :value)
            value = formatter.call(context)
            acc[field.name] = value unless hooks.any?(:exclude_field?, context)
          when ObjectField
            value = hooks.reduce_into(:object_value, context, :value)
            next if hooks.any?(:exclude_object?, context)

            v2 = instances[field.blueprint].is_a? V2::Base
            value = v2 ? field.blueprint.serializer.call(value, options, instances) : field.blueprint.render(value, options) if value
            acc[field.name] = value
          when Collection
            value = hooks.reduce_into(:collection_value, context, :value)
            next if hooks.any?(:exclude_collection?, context)

            v2 = instances[field.blueprint].is_a? V2::Base
            value = v2 ? value.map { |val| field.blueprint.serializer.call(val, options, instances) } : field.blueprint.render(value, options) if value
            acc[field.name] = value
          end
        end

        context.field = nil
        context.value = result
        hooks.reduce_into(:blueprint_output, context, :value)
      end
    end
  end
end
