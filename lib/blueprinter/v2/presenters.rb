# frozen_string_literal: true

module Blueprinter
  module V2
    module Presenters
      module Field
        # @param ctx [Blueprinter::V2::Context::Field]
        # @param value [Object]
        def self.present(ctx, value, parent:, instances:, store:, depth:)
          return value
          ctx.blueprint.class.serializer.formatter.call(value, ctx)
        end
      end

      module Object
        # @param ctx [Blueprinter::V2::Context::Field]
        # @param value [Object]
        def self.present(ctx, value, parent:, instances:, store:, depth:)
          parent.field = field
          parent.object = object
          ctx.field.blueprint.serializer.object(value, ctx.options, parent:, instances:, store:, depth: depth + 1)
        end
      end

      module Collection
        # @param ctx [Blueprinter::V2::Context::Field]
        # @param value [Object]
        def self.present(ctx, value, parent:, instances:, store:, depth:)
          parent.field = field
          parent.object = object
          ctx.field.blueprint.serializer.collection(value, ctx.options, parent:, instances:, store:, depth: depth + 1)
        end
      end

      module V1Association
        # @param ctx [Blueprinter::V2::Context::Field]
        # @param value [Object]
        def self.present(ctx, value, parent:, instances:, store:, depth:)
          opts = { v2_instances: instances, v2_depth: depth + 1, v2_store: store }
          field.blueprint.hashify(value, view_name: :default, local_options: ctx.options.dup.merge(opts))
        end
      end
    end
  end
end
