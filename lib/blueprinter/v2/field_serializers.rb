# frozen_string_literal: true

module Blueprinter
  module V2
    # rubocop:disable Lint/UnusedMethodArgument
    module FieldSerializers
      # Serializer for V2 objects
      module Object
        def self.serialize(blueprint_class, value, options, parent:, instances:, store:, depth:)
          blueprint_class.serializer.object(value, options, parent:, instances:, store:, depth: depth + 1)
        end
      end

      # Serializer for V2 collections
      module Collection
        def self.serialize(blueprint_class, value, options, parent:, instances:, store:, depth:)
          blueprint_class.serializer.collection(value, options, parent:, instances:, store:, depth: depth + 1)
        end
      end

      # Serializer for V1 associations
      module V1Association
        def self.serialize(blueprint_class, value, options, parent:, instances:, store:, depth:)
          opts = { v2_instances: instances, v2_depth: depth + 1, v2_store: store }
          blueprint_class.hashify(value, view_name: :default, local_options: options.dup.merge(opts))
        end
      end
    end
    # rubocop:enable Lint/UnusedMethodArgument
  end
end
