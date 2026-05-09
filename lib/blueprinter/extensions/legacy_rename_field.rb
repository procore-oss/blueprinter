# frozen_string_literal: true

module Blueprinter
  module Extensions
    #
    # An extension to add support for V1's `name` field option.
    #
    # ```
    # class ApplicationBlueprint < Blueprinter::V2::Base
    #   add Blueprinter::Extensions::LegacyRenameField.new
    # end
    # ```
    #
    # In V2 when a serialized field name doesn't match the name in the object, you represent it like this:
    #
    #   # Populate the "desc" field using the object's "description"
    #   field :desc, source: :description
    #
    # In V1 it was backwards:
    #
    #   # Populate the "desc" field using the object's "description"
    #   field :description, name: :desc
    #
    # This extension allows the V1 style to continue working.
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
