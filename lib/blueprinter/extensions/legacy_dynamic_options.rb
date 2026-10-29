# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # Support for Legacy/V1's `:options` option on associations.
    #
    # For optimal performance it's recommended to add this extension only to Blueprints/views that use dynamic options,
    # rather than to `ApplicationBlueprint`.
    #
    # ```
    # class WidgetBlueprint < ApplicationBlueprint
    #   add Blueprinter::Extensions::LegacyDynamicOptions.new
    #
    #   # Pass a Hash
    #   association :category, CategoryBlueprint, options: { foo: 'bar' }
    #
    #   # Or a Proc. It will be passed the current object (not the associated object).
    #   association :category, CategoryBlueprint, options: ->(widget) {
    #     { foo: widget.foo }
    #   }
    # end
    # ```
    #
    # NOTE: This was provided as a workaround when legacy/V1 began freezing options. In V2, it's recommended to use
    # `ctx.store` in a block, as it's intended to be modifiable.
    #
    class LegacyDynamicOptions < Extension
      # @!visibility private
      def initialize
        around_object_value :apply
        around_collection_value :apply
      end

      # @param ctx [Blueprinter::V2::Context::Field]
      # @!visibility private
      def apply(ctx)
        additional_opts =
          case (opts = ctx.field.options[:options])
          when Hash then opts
          when Proc then opts.call(ctx.object)
          end

        # Only applies to this association and anything nested beneath it
        ctx.options = ctx.options.merge(additional_opts).freeze if additional_opts
        yield ctx
      end
    end
  end
end
