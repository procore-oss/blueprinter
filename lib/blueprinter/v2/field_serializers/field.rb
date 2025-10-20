# frozen_string_literal: true

module Blueprinter
  module V2
    module FieldSerializers
      # Serializesr for regular fields
      class Field < Base
        def serialize(ctx, result)
          value = catch Serializer::SKIP do
            # perf boost from "unrolled" built-in hooks
            @cond.around_field_value(ctx) do
              @defaults.around_field_value(ctx) do
                # perf boost by skipping `reduce_around` when no extensions use it
                if @hook_around_field_value
                  @hooks.reduce_around(:around_field_value, ctx) do
                    @extractor.around_field_value ctx
                  end
                else
                  @extractor.around_field_value ctx
                end
              end
            end
          end
          return if value == Serializer::SKIP

          result[ctx.field.name] = @formatter.call(value, ctx)
        end

        private

        # We save a lot of time by skipping hooks that aren't used
        def find_used_hooks!
          @hook_around_field_value = @hooks.registered? :around_field_value
        end
      end
    end
  end
end
