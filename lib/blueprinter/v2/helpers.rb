# frozen_string_literal: true

module Blueprinter
  module V2
    module Helpers
      def skip = throw Serializer::SIGNAL, Serializer::SIG_SKIP
    end
  end
end
