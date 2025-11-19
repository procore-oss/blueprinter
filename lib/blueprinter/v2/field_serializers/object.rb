# frozen_string_literal: true

module Blueprinter
  module V2
    module FieldSerializers
      # Serializesr for object fields
      class Object < Base
        def serialize(ctx, result)
          value = catch Serializer::SIGNAL do
            # perf boost from "unrolled" built-in hooks
            @conditionals.around_object_value(ctx) do |ctx|
              @defaults.around_object_value(ctx) do |ctx|
                # perf boost by skipping `around` when no extensions use it
                if @hook_around_object_value
                  @hooks.around(:around_object_value, ctx) do |ctx|
                    extract ctx
                  end
                else
                  extract ctx
                end
              end
            end
          end
          return if value == Serializer::SIG_SKIP

          result[ctx.field.name] = value.nil? ? nil : blueprint_value(value, ctx)
        end

        private

        def blueprint_value(value, ctx)
          field_blueprint = ctx.field.blueprint
          if @instances.blueprint(field_blueprint).is_a? V2::Base
            parent = Context::Parent.new(ctx.blueprint.class, ctx.field, ctx.object)
            child_serializer = @instances.serializer(field_blueprint, ctx.options, ctx.depth + 1)
            child_serializer.object(value, parent:, depth: ctx.depth + 1)
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
