# frozen_string_literal: true

require 'blueprinter/v2/extensions/conditional_fields'
require 'blueprinter/v2/extensions/default_values'
require 'blueprinter/v2/extensions/exclude_if_empty'
require 'blueprinter/v2/extensions/exclude_if_nil'
require 'blueprinter/v2/extensions/extraction'
require 'blueprinter/v2/extensions/serialization'
require 'blueprinter/v2/extractor'
require 'blueprinter/v2/formatter'
require 'blueprinter/v2/hooks'

module Blueprinter
  module V2
    class Serializer
      # Wraps everything we pass to formatters and most extension hooks
      Context = Struct.new(:blueprint, :field, :value, :object, :options, :instances)

      # Core extensions that must run at the start of serialization
      CORE_START = [
        Extensions::Extraction,
        Extensions::ConditionalFields,
        Extensions::DefaultValues,
        Extensions::ExcludeIfEmpty,
        Extensions::ExcludeIfNil
      ].freeze

      # Core extensions that must run at the end of serialization
      CORE_FINISH = [
        Extensions::Serialization
      ].freeze

      attr_reader :blueprint, :formatter, :hooks

      def initialize(blueprint)
        extensions = CORE_START.map(&:new) + blueprint.extensions + CORE_FINISH.map(&:new)
        @formatter = Formatter.new extensions
        @hooks = Hooks.new extensions
        @blueprint = blueprint
      end

      def call(obj, options, instance_cache)
        bp = instance_cache[blueprint]
        reflection = blueprint.reflections[:default]

        result = reflection.fields.each_with_object({}) do |(_, field), acc|
          value = hooks.reduce(:field_value, nil) { |val| Context.new(bp, field, val, obj, options, instance_cache) }
          value = formatter.call(Context.new(bp, field, value, obj, options, instance_cache))
          acc[field.name] = value unless hooks.any?(:exclude_field?, Context.new(bp, field, value, obj, options, instance_cache))
        end

        result = reflection.objects.each_with_object(result) do |(_, field), acc|
          value = hooks.reduce(:object_value, nil) { |val| Context.new(bp, field, val, obj, options, instance_cache) }
          acc[field.name] = value unless hooks.any?(:exclude_object?, Context.new(bp, field, value, obj, options, instance_cache))
        end

        reflection.collections.each_with_object(result) do |(_, field), acc|
          value = hooks.reduce(:collection_value, nil) { |val| Context.new(bp, field, val, obj, options, instance_cache) }
          acc[field.name] = value unless hooks.any?(:exclude_collection?, Context.new(bp, field, value, obj, options, instance_cache))
        end
      end
    end
  end
end
