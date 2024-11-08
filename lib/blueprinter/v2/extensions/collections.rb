# frozen_string_literal: true

require 'set'

module Blueprinter
  module V2
    module Extensions
      class Collections < Extension
        def collection?(object)
          case object
          when Array, Set, Enumerator then true
          else false
          end
        end
      end
    end
  end
end
