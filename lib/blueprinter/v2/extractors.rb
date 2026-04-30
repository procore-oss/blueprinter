# frozen_string_literal: true

module Blueprinter
  module V2
    # Field value extractors. They must all conform to the same "interface".
    # rubocop:disable Lint/UnusedMethodArgument
    module Extractors
      # Extracts field value from a Proc
      module Proc
        # @param field [Blueprinter::V2::Fields] The field to extract
        # @param object [Object] The object to extract the field from
        # @param ctx [Blueprinter::V2::Context::Field]
        # @return [Object] The field value
        def self.extract(field, object, ctx:)
          field.value_proc.call(object, ctx)
        end
      end

      # Extracts field value from a Hash or object
      module Property
        # @param field [Blueprinter::V2::Fields] The field to extract
        # @param object [Object] The object to extract the field from
        # @param ctx [Blueprinter::V2::Context::Field] Unused
        # @return [Object] The field value
        def self.extract(field, object, ctx: nil)
          if object.is_a? Hash
            object[field.from] || object[field.from_str]
          else
            object.public_send(field.from)
          end
        end
      end
    end
    # rubocop:enable Lint/UnusedMethodArgument
  end
end
