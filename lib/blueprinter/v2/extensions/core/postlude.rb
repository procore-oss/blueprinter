# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      module Core
        #
        # A core extension with hooks that must run AFTER all others.
        #
        class Postlude < Extension
          # @param ctx [Blueprinter::V2::Context::Result]
          def object_output(ctx)
            return ctx.result unless ctx.depth == 1

            root_name = ctx.options[:root] || ctx.blueprint.class.options[:root]
            return ctx.result if root_name.nil?

            root = { root_name => ctx.result }
            if (meta = ctx.options[:meta] || ctx.blueprint.class.options[:meta])
              meta = ctx.blueprint.instance_exec(ctx, &meta) if meta.is_a? Proc
              root[:meta] = meta
            end
            root
          end

          alias collection_output object_output

          def hidden? = true
        end
      end
    end
  end
end
