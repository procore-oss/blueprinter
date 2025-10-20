# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      module Core
        #
        # A core extension with hooks that must run AFTER all others.
        #
        class Postlude < Extension
          # @param ctx [Blueprinter::V2::Context::Object]
          def around_serialize_object(ctx)
            result = yield ctx.object
            return result unless ctx.depth == 1

            root_name = ctx.options[:root] || ctx.blueprint.class.options[:root]
            return result if root_name.nil?

            root = { root_name => result }
            if (meta = ctx.options[:meta] || ctx.blueprint.class.options[:meta])
              meta = ctx.blueprint.instance_exec(ctx, &meta) if meta.is_a? Proc
              root[:meta] = meta
            end
            root
          end

          alias around_serialize_collection around_serialize_object

          def hidden? = true
        end
      end
    end
  end
end
