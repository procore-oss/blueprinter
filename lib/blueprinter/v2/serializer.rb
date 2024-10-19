# frozen_string_literal: true

module Blueprinter
  module V2
    class Serializer
      attr_reader :blueprint, :ref, :formatters

      def initialize(blueprint)
        @blueprint = blueprint
        @ref = blueprint.reflections[:default]
        @formatters = extract_formatters blueprint
      end

      def call(obj, options, blueprint_instances)
        bp = blueprint_instances[blueprint] ||= blueprint.new
        result = ref.fields.each_with_object({}) do |(_, field), acc|
          # TODO
        end
        ref.associations.each_with_object(result) do |(_, assoc), acc|
          # TODO
        end
      end

      private

      # @return [Hash<Class, Proc>]
      def extract_formatters(extensions)
        blueprint.extensions.reduce({}) do |acc, ext|
          fmts = ext.class.formatters.transform_values do |fmt|
            fmt.is_a?(Proc) ? fmt : ext.method(fmt)
          end
          acc.merge(fmts)
        end
      end
    end
  end
end
