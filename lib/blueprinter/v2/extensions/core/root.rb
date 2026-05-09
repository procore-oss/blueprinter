# frozen_string_literal: true

module Blueprinter
  module V2
    module Extensions
      module Core
        #
        # A core extension for wrapping the result with metadata.
        # @!visibility private
        #
        class Root < Extension
          # @param ctx [Blueprinter::V2::Context::Result]
          def around_result(ctx)
            result = yield ctx
            root_name = ctx.options[:root]
            return result if serialized?(result) || !root_name

            root = { root_name => result }
            root[:meta] = ctx.options[:meta] if ctx.options[:meta]
            root
          end

          def hidden? = true
        end
      end
    end
  end
end
