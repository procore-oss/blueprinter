# frozen_string_literal: true

module Blueprinter
  module V2
    module Extractors
      module Proc
        # @param ctx [Blueprinter::V2::Context::Field]
        def self.extract(ctx, blueprint, field, object)
          blueprint.instance_exec(object, ctx, &field.value_proc)
        end
      end

      module Property
        # @param ctx [Blueprinter::V2::Context::Field]
        def self.extract(_ctx, _blueprint, field, object)
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
