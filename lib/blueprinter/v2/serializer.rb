# frozen_string_literal: true

module Blueprinter
  module V2
    class Serializer
      attr_reader :blueprint, :ref, :formatters, :default_extractor

      def initialize(blueprint)
        @blueprint = blueprint
        @ref = blueprint.reflections[:default]
        @formatters = extract_formatters
        @default_extractor = blueprint.extractor || Extractor
      end

      def call(obj, options, instance_cache)
        result = ref.fields.each_with_object({}) do |(_, field), acc|
          opts = field.custom_options.merge(options)
          val = format extract_field(field, obj, opts, instance_cache), opts
          acc[field.name] = val unless val.nil? && blueprint.options.exclude_nil
        end

        ref.associations.each_with_object(result) do |(_, field), acc|
          opts = field.custom_options.merge(options)
          val = extract_association(field, obj, opts, instance_cache)
          acc[field.name] = val unless val.nil? && blueprint.options.exclude_nil
        end
      end

      private

      def format(val, options)
        fmt = formatters[val.class]
        fmt ? fmt.call(val, options) : val
      end

      def extract_field(field, obj, options, instance_cache)
        if field.value_proc
          instance_cache[blueprint].instance_exec(obj, options, &field.value_proc)
        else
          extractor = instance_cache[field.extractor || default_extractor]
          extractor.call(field.from, obj, options)
        end
      end

      def extract_association(field, obj, options, instance_cache)
        val =
          if field.value_proc
            instance_cache[blueprint].instance_exec(obj, options, &field.value_proc)
          else
            extractor = instance_cache[field.extractor || default_extractor]
            extractor.call(field.from, obj, options)
          end

        # TODO support V1 blueprints
        if field.collection
          val.each.map { |v| field.blueprint.serializer.call(v, options, instance_cache) }
        else
          field.blueprint.serializer.call(val, options, instance_cache)
        end
      end

      # @return [Hash<Class, Proc>]
      def extract_formatters
        blueprint.extensions.reduce({}) do |acc, ext|
          fmts = ext.class.formatters.transform_values do |fmt|
            fmt.is_a?(Proc) ? fmt : ext.public_method(fmt)
          end
          acc.merge(fmts)
        end
      end
    end
  end
end
