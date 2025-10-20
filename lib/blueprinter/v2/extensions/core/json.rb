# frozen_string_literal: true

require 'json'

module Blueprinter
  module V2
    module Extensions
      module Core
        #
        # A core extension for serializing results to JSON.
        #
        class Json < Extension
          # @param ctx [Blueprinter::V2::Context::Result]
          def around_result(ctx)
            result = yield ctx
            return result if final? result

            case ctx.format
            when :hash then result
            when :json then final ::JSON.dump result
            else raise BlueprinterError, "Unrecognized serialization format `#{ctx.format.inspect}`"
            end
          end

          def hidden? = true
        end
      end
    end
  end
end
