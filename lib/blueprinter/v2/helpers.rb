# frozen_string_literal: true

module Blueprinter
  module V2
    module Helpers
      def skip = Serializer::SKIP

      def skip?(val) = val == Serializer::SKIP
    end
  end
end
