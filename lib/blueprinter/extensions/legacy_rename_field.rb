# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # Support for Legacy/V1's `name` option.
    #
    class LegacyRenameField < Extension
      # @param ctx [Blueprinter::V2::Context::Init]
      # @!visibility private
      def around_blueprint_init(ctx)
        ctx.fields.each do |field|
          if (name = field.options[:name])
            field.source = field.name
            field.name = name
          end
        end
        yield ctx
      end
    end
  end
end
