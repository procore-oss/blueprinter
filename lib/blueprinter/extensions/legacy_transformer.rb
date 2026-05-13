# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # Support for Legacy/V1's transformers.
    #
    class LegacyTransformer < Extension
      # @param *transformers [Class] One or more transformers (Blueprinter::Transformer)
      def initialize(*transformers)
        @transformers = transformers
      end

      # @param ctx [Blueprinter::V2::Context::Object]
      # @!visibility private
      def around_blueprint(ctx)
        hash = yield ctx
        @transformers.each do |klass|
          transformer = ctx.store[klass.object_id] ||= klass.new
          transformer.transform(hash, ctx.object, ctx.options)
        end
        hash
      end
    end
  end
end
