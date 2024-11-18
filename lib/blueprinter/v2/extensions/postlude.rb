# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      # Hooks that should run after everything else
      class Postlude < Extension
        def output_object(ctx)
          root_name = ctx.options[:root] || ctx.blueprint.class.options[:root]
          return ctx.value if root_name.nil?

          root = { root_name => ctx.value }
          if (meta = ctx.options[:meta] || ctx.blueprint.class.options[:meta])
            meta = ctx.blueprint.instance_exec(ctx, &meta) if meta.is_a? Proc
            root[:meta] = meta
          end
          root
        end

        def output_collection(ctx)
          output_object ctx
        end
      end
    end
  end
end
