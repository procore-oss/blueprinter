# frozen_string_literal: true

module Blueprinter
  module V2
    module FieldSerializers
      # Serializesr for regular fields
      class Field < Base
        def serialize(ctx, result)
          value = catch Serializer::SKIP do
            # perf boost from "unrolled" built-in hooks
            @conditionals.around_field_value(ctx) do |ctx|
              @defaults.around_field_value(ctx) do |ctx|
                # perf boost by skipping `around` when no extensions use it
                if @hook_around_field_value
                  @hooks.around(:around_field_value, ctx) do |ctx|
                    extract ctx
                  end
                else
                  extract ctx
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
