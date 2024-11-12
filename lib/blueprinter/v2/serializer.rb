# frozen_string_literal: true

require 'blueprinter/hooks'
require 'blueprinter/v2/formatter'

module Blueprinter
  module V2
    class Serializer
      attr_reader :blueprint, :formatter, :hooks, :values, :exclusions

      def initialize(blueprint)
        @hooks = Hooks.new([Extensions::Collections.new] + blueprint.extensions + [Extensions::Output.new])
        @formatter = Formatter.new(blueprint)
        @blueprint = blueprint
        # "Unroll" these hooks for a significant speed boost
        @values = Extensions::Values.new
        @exclusions = Extensions::Exclusions.new
        block_unused_hooks!
      end

      def call(object, options, instances, store)
        ctx = Context.new(instances[blueprint], nil, nil, nil, options, instances, store)
        store[blueprint.object_id] ||= prepare! ctx

        ctx.object = object
        hooks.reduce_into(:blueprint_input, ctx, :object) if @run_blueprint_input

        result = ctx.store[blueprint.object_id][:fields].each_with_object({}) do |field, acc|
          ctx.field = field
          ctx.value = nil

          case field
          when Field
            ctx.value = values.field_value ctx
            hooks.reduce_into(:field_value, ctx, :value) if @run_field_value
            ctx.value = formatter.call(ctx)
            next if exclusions.exclude_field?(ctx) || (@run_exclude_field && hooks.any?(:exclude_field?, ctx))

            acc[field.name] = ctx.value
          when ObjectField
            ctx.value = values.object_value ctx
            hooks.reduce_into(:object_value, ctx, :value) if @run_object_value
            next if exclusions.exclude_object?(ctx) || (@run_exclude_object && hooks.any?(:exclude_object?, ctx))

            v2 = instances[field.blueprint].is_a? V2::Base
            ctx.value = v2 ? field.blueprint.serializer.call(ctx.value, options, instances, store) : field.blueprint.render(ctx.value, options) if ctx.value
            acc[field.name] = ctx.value
          when Collection
            ctx.value = values.collection_value ctx
            hooks.reduce_into(:collection_value, ctx, :value) if @run_collection_value
            next if exclusions.exclude_collection?(ctx) || (@run_exclude_collection && hooks.any?(:exclude_collection?, ctx))

            v2 = instances[field.blueprint].is_a? V2::Base
            ctx.value = v2 ? ctx.value.map { |val| field.blueprint.serializer.call(val, options, instances, store) } : field.blueprint.render(ctx.value, options) if ctx.value
            acc[field.name] = ctx.value
          end
        end

        ctx.field = nil
        ctx.value = result
        @run_blueprint_output ? hooks.reduce_into(:blueprint_output, ctx, :value) : ctx.value
      end

      private

      def prepare!(ctx)
        values.prepare ctx
        exclusions.prepare ctx
        hooks.each(:prepare, ctx) if @run_prepare
        { fields: hooks.last(:blueprint_fields, ctx).freeze }.freeze
      end

      def block_unused_hooks!
        @run_prepare = hooks.has? :prepare
        @run_blueprint_input = hooks.has? :blueprint_input
        @run_blueprint_output = hooks.has? :blueprint_output
        @run_field_value = hooks.has? :field_value
        @run_object_value = hooks.has? :object_value
        @run_collection_value = hooks.has? :collection_value
        @run_exclude_field = hooks.has? :exclude_field?
        @run_exclude_object = hooks.has? :exclude_object?
        @run_exclude_collection = hooks.has? :exclude_collection?
      end
    end
  end
end
