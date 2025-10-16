# frozen_string_literal: true

require 'json'

module Blueprinter
  module V2
    module Extensions
      module Core
        #
        # A core extension to extract values from objects.
        #
        class Extractor < Extension
          # If someone inherits from this, they probably don't want it hidden
          def self.inherited(subclass)
            subclass.class_eval do
              def hidden? = false
            end
          end

          # @param ctx [Blueprinter::V2::Context::Field]
          def extract_value(ctx)
            if ctx.object.is_a? Hash
              ctx.object[ctx.field.from] || ctx.object[ctx.field.from_str]
            else
              ctx.object.public_send(ctx.field.from)
            end
          end

          def hidden? = true
        end
      end
    end
  end
end
