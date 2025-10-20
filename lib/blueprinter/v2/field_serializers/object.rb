# frozen_string_literal: true

module Blueprinter
  module V2
    module FieldSerializers
      # Serializesr for object fields
      class Object < Base
        def serialize(ctx, result)
          value = catch Serializer::SKIP do
            # perf boost from "unrolled" built-in hooks
            @cond.around_object_value(ctx) do
              @defaults.around_object_value(ctx) do
                # perf boost by skipping `reduce_around` when no extensions use it
                if @hook_around_object_value
                  @hooks.reduce_around(:around_object_value, ctx) do
                    @extractor.around_object_value ctx
                  end
                else
                  @extractor.around_object_value ctx
                end
              end
            end
          end
          return if value == Serializer::SKIP

          result[ctx.field.name] = value.nil? ? nil : blueprint_value(value, ctx)
        end

        private

        def blueprint_value(value, ctx)
          field_blueprint = ctx.field.blueprint
          if @instances.blueprint(field_blueprint).is_a? V2::Base
            child_serializer = @instances.serializer(field_blueprint, ctx.options, ctx.depth + 1)
            child_serializer.object(value, depth: ctx.depth + 1)
          else
            opts = { v2_instances: @instances, v2_depth: ctx.depth }
            field_blueprint.hashify(value, view_name: :default, local_options: ctx.options.dup.merge(opts))
          end
        end

        # We save a lot of time by skipping hooks that aren't used
        def find_used_hooks!
          @hook_around_object_value = @hooks.registered? :around_object_value
        end
      end
    end
  end
end
