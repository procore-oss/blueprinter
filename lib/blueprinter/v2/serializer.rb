# frozen_string_literal: true

module Blueprinter
  module V2
    class Serializer
      attr_reader :blueprint, :ref, :formatters, :default_extractor

      def initialize(blueprint)
        @blueprint = blueprint
        @ref = blueprint.reflections[:default]
        @formatters = extract_formatters
        @default_extractor = blueprint.extractor || TODO
      end

      def call(obj, options, blueprint_instances)
        bp = blueprint_instances[blueprint]

        result = ref.fields.each_with_object({}) do |(_, field), acc|
          opts = field.custom_options.merge(options)
          val = format extract_field(field, obj, opts, bp), opts
          acc[field.name] = val unless val.nil? && blueprint.options.exclude_nil
        end

        ref.associations.each_with_object(result) do |(_, field), acc|
          opts = field.custom_options.merge(options)
          acc[field.name] =
            if field.collection
              obj.each.map { |o| extract_association_member(field, o, opts, blueprint_instances) }
            else
              extract_association_member(field, obj, opts, blueprint_instances)
            end
        end
      end

      private

      def format(val, options)
        fmt = formatter[val.class]
        fmt ? fmt.call(val, options) : val
      end

      def extract_field(field, obj, options, blueprint_instance)
        if field.value_proc
          blueprint_instance.instance_exec(obj, options, &field.value_proc)
        else
          extractor = field.extractor || default_extractor
          # TODO
        end
      end

      def extract_association_member(field, obj, options, blueprint_instances)
        val =
          if field.value_proc
            blueprint_instances[blueprint].instance_exec(obj, options, &field.value_proc)
          else
            extractor = field.extractor || default_extractor
            # TODO
          end
        # TODO support V1 blueprints
        field.blueprint.serializer.call(val, options, blueprint_instances)
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
