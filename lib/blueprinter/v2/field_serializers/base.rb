# frozen_string_literal: true

module Blueprinter
  module V2
    module FieldSerializers
      class Base
        attr_reader :field

        def initialize(field, serializer)
          @field = field
          @instances = serializer.instances
          @hooks = serializer.hooks
          @defaults = serializer.defaults
          @conditionals = serializer.conditionals
          @formatter = serializer.formatter
          find_used_hooks!
        end

        # @param ctx [Blueprinter::V2::Context::Field]
        def extract(ctx)
          field = ctx.field
          object = ctx.object

          if field.value_proc
            ctx.blueprint.instance_exec(ctx.object, ctx, &field.value_proc)
          elsif object.is_a? Hash
            object[field.from] || object[field.from_str]
          else
            object.public_send(field.from)
          end
        end
      end
    end
  end
end
