# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      module Core
        #
        # A core extension for wrapping the result with metadata.
        #
        class Wrapper < Extension
          # @param ctx [Blueprinter::V2::Context::Result]
          def around_result(ctx)
            result = yield ctx
            return result if final? result

            root_name = ctx.options[:root] || ctx.blueprint.class.options[:root]
            return result if root_name.nil? || ctx.options[:root] == false

            wrap result, root_name, ctx
          end

          def hidden? = true

          private

          def wrap(result, root_name, ctx)
            root = { root_name => result }
            if (meta = ctx.options[:meta] || ctx.blueprint.class.options[:meta])
              meta = ctx.blueprint.instance_exec(ctx, &meta) if meta.is_a? Proc
              root[:meta] = meta
            end
            root
          end
        end
      end
    end
  end
end
