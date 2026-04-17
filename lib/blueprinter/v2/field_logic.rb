# frozen_string_literal: true

module Blueprinter
  module V2
    module FieldLogic
      # @param ctx [Blueprinter::V2::Context::Field]
      def self.skip?(ctx, blueprint, field)
        if (cond = field.options[:if])
          result = cond.is_a?(Proc) \
            ? blueprint.instance_exec(ctx, &cond) \
            : blueprint.public_send(cond, ctx)
          return true unless result
        end

        if (cond = field.options[:unless])
          result = cond.is_a?(Proc) \
            ? blueprint.instance_exec(ctx, &cond) \
            : blueprint.public_send(cond, ctx)
          return true if result
        end

        false
      end

      # @param ctx [Blueprinter::V2::Context::Field]
      def self.value_or_default(ctx, blueprint, field, value)
        default_if = field.options[:default_if]
        return value unless value.nil? || (default_if && use_default?(default_if, value, ctx))

        case (default_value = field.options[:default])
        when Proc then blueprint.instance_exec(value, ctx, &default_value)
        when Symbol then blueprint.public_send(default_value, value, ctx)
        else default_value
        end
      end

      def self.use_default?(cond, value, ctx)
        case cond
        when Proc then ctx.blueprint.instance_exec(value, ctx, &cond)
        else ctx.blueprint.public_send(cond, value, ctx)
        end
      end

      module ProcExtractor
        # @param ctx [Blueprinter::V2::Context::Field]
        def self.extract(ctx, blueprint, field, object)
          blueprint.instance_exec(object, ctx, &field.value_proc)
        end
      end

      module PropertyExtractor
        # @param ctx [Blueprinter::V2::Context::Field]
        def self.extract(_ctx, _blueprint, field, object)
          if object.is_a? Hash
            object[field.from] || object[field.from_str]
          else
            object.public_send(field.from)
          end
        end
      end

      module ObjectSerializer
        def self.serialize(blueprint_class, value, options, parent:, instances:, store:, depth:)
          blueprint_class.serializer.object(value, options, parent:, instances:, store:, depth: depth + 1)
        end
      end

      module CollectionSerializer
        def self.serialize(blueprint_class, value, options, parent:, instances:, store:, depth:)
          blueprint_class.serializer.collection(value, options, parent:, instances:, store:, depth: depth + 1)
        end
      end

      module V1AssociationSerializer
        def self.serialize(blueprint_class, value, options, parent:, instances:, store:, depth:)
          opts = { v2_instances: instances, v2_depth: depth + 1, v2_store: store }
          blueprint.hashify(value, view_name: :default, local_options: options.dup.merge(opts))
        end
      end
    end
  end
end
