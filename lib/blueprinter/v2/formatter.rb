# frozen_string_literal: true

module Blueprinter
  module V2
    # An interface for formatting values against extensions
    class Formatter
      def initialize(extensions)
        @formatters = extensions.reduce({}) do |acc, ext|
          fmts = ext.class.formatters.transform_values do |fmt|
            if fmt.is_a? Proc
              ->(context) { ext.instance_exec(context, &fmt) }
            else
              ext.public_method(fmt)
            end
          end
          acc.merge(fmts)
        end
      end

      # @param context [Blueprinter::V2::Serializer::Context]
      def call(context)
        fmt = @formatters[context.value.class]
        fmt ? fmt.call(context) : context.value
      end
    end
  end
end
