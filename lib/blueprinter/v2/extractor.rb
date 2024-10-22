# frozen_string_literal: true

module Blueprinter
  module V2
    # The default extractor and base class for custom extractors
    class Extractor
      def field(blueprint, field, object, options)
        if field.value_proc
          blueprint.instance_exec(object, options, &field.value_proc)
        elsif object.is_a? Hash
          object[field.from]
        else
          object.public_send(field.from)
        end
      end

      def object(blueprint, field, object, options)
        field(blueprint, field, object, options)
      end

      def collection(blueprint, field, object, options)
        field(blueprint, field, object, options)
      end
    end
  end
end
