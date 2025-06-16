# frozen_string_literal: true

require 'json'

module Blueprinter
  module V2
    module Extensions
      module Core
        #
        # A core extension with hooks that must run BEFORE all others.
        #
        class Prelude < Extension
          # @param ctx [Blueprinter::V2::Context::Render]
          def blueprint_fields(ctx) = ctx.fields

          # @param ctx [Blueprinter::V2::Context::Result]
          def json(ctx)
            JSON.dump ctx.result
          end

          def hidden? = true
        end
      end
    end
  end
end
