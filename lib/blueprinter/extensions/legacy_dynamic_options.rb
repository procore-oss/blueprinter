# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # Support for Legacy/V1's `:options` option on associations.
    #
    class LegacyDynamicOptions < Extension
      # @!visibility private
      def apply(ctx)
        ctx.fields.each do |field|
          additional_opts =
            case (opts = field.options[:options])
            when Hash then opts
            when Proc then opts.call(ctx.object)
            end
          ctx.options = ctx.options.merge(additional_opts).freeze if additional_opts
        end
        yield ctx
      end

      # @!visibility private
      alias around_serialize_object apply

      # @!visibility private
      alias around_serialize_collection apply
    end
  end
end
