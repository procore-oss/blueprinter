# frozen_string_literal: true

require 'set'

module Blueprinter
  module V2
    module Extensions
      module Core
        #
        # A core extension with hooks that must run BEFORE all others.
        #
        class Prelude < Extension
          def collection?(object)
            case object
            when Array, Set, Enumerator then true
            else false
            end
          end

          def blueprint_fields(ctx)
            ctx.blueprint.class.reflections[:default].ordered
          end

          def hidden? = true
        end
      end
    end
  end
end
