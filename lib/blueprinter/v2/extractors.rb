# frozen_string_literal: true

module Blueprinter
  module V2
    # Field value extractors
    module Extractors
      # Extracts field value from a Proc
      module Proc
        # @param ctx [Blueprinter::V2::Context::Field]
        # @return [Object] The field value
        def self.extract(ctx)
          ctx.blueprint.instance_exec(ctx.object, ctx, &ctx.field.value_proc)
        end
      end

      # Extracts field value from a Hash or object
      module Property
        # @param ctx [Blueprinter::V2::Context::Field]
        # @return [Object] The field value
        def self.extract(ctx)
          if ctx.object.is_a? Hash
            ctx.object[ctx.field.from] || ctx.object[ctx.field.from_str]
          else
            ctx.object.public_send(ctx.field.from)
          end
        end

        # Fast-path extraction that avoids a Context::Field allocation.
        # @param object [Object] The object or hash being serialized
        # @param field [Blueprinter::V2::Fields::Field|Object|Collection]
        # @return [Object] The field value
        def self.extract_simple(object, field)
          if object.is_a? Hash
            object[field.from] || object[field.from_str]
          else
            object.public_send(field.from)
          end
        end
      end
    end
  end
end
