# frozen_string_literal: true

module Blueprinter
  module V2
    # The default extractor, and the suggested base class for custom extractors
    class Extractor
      def extract(name, object, _options)
        case object
        when Hash
          object[name]
        else
          object.public_send(name)
        end
      end
    end
  end
end
