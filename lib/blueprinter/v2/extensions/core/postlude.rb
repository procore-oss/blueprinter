# frozen_string_literal: true

require 'json'

module Blueprinter
  module V2
    module Extensions
      module Core
        #
        # A core extension with hooks that must run AFTER all others.
        #
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

          def json(ctx)
            JSON.dump ctx.value
          end

          def hidden? = true
        end
      end
    end
  end
end
