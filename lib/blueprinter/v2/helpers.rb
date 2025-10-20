# frozen_string_literal: true

module Blueprinter
  module V2
    module Helpers
      def skip = throw Serializer::SKIP, Serializer::SKIP
    end
  end
end
