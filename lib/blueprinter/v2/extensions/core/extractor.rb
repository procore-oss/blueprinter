# frozen_string_literal: true

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
          def around_field_value(ctx)
            field = ctx.field
            object = ctx.object

            if field.value_proc
              ctx.blueprint.instance_exec(ctx, &field.value_proc)
            elsif object.is_a? Hash
              object[field.from] || object[field.from_str]
            else
              object.public_send(field.from)
            end
          end

          alias around_object_value around_field_value
          alias around_collection_value around_field_value

          def hidden? = true
        end
      end
    end
  end
end
