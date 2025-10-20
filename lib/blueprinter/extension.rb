# frozen_string_literal: true

module Blueprinter
  #
  # Base class for all extensions.
  #
  # V2 hook call order:
  #
  # - around_hook (called around any other extension hook)
  # - blueprint
  # - blueprint_fields
  # - blueprint_setup
  # - around_serialize_object | around_serialize_collection
  #   - around_blueprint
  #     - around_field_value | around_object_value | around_collection_value
  #       - blueprint …
  # - json
  #
  # V1 hook call order:
  #  - pre_render
  #
  class Extension
    include V2::Helpers

    HOOKS = %i[
      around_hook
      blueprint
      blueprint_fields
      blueprint_setup
      around_serialize_object
      around_serialize_collection
      around_blueprint
      around_field_value
      around_object_value
      around_collection_value
      json
      pre_render
    ].freeze

    # @return [Array<Symbol>] The names of the hooks implemented in this extension
    def self.hooks
      @_hooks ||= (public_instance_methods(true) & HOOKS).freeze
    end

    # If this returns true, around_hook will not be called when this extension's hooks are run. Used by core extensions.
    def hidden? = false

    # around_serialize_object: Runs around serialization of a Blueprint object.
    # @param context [Blueprinter::V2::Context::Object]

    # around_serialize_collection: Runs around serialization of a Blueprint collection.
    # @param context [Blueprinter::V2::Context::Object]

    # around_blueprint: Runs around serialization of every Blueprint.
    # @param context [Blueprinter::V2::Context::Object]

    # around_field_value TODO

    # around_object_value TODO

    # around_collection_value TODO

    # blueprint: Returns the blueprint class to render with. The context's "fields" field will be empty.
    # @param context [Blueprinter::V2::Context::Render]

    # blueprint_fields: Returns the fields that should be included in the correct order. Default is all fields in the order
    # in which they were defined.
    # NOTE If there are multiple blueprint_fields hooks, only the last one is called.
    # NOTE Only runs once per Blueprint per render.
    # @param context [Blueprinter::V2::Context::Render]
    # @return [Array<Blueprinter::V2::Fields::Field|Blueprinter::V2::Fields::Object|Blueprinter::V2::Fields::Collection>]

    # blueprint_setup: Called once per blueprint per render. A common use is to pre-calculate certain options
    # and cache them in context.data, so we don't have to recalculate them for every field.
    # @param context [Blueprinter::V2::Context::Render]

    # json: Override the default JSON encoder. The returned string will be the JSON output.
    # NOTE If there are multiple json hooks, only the final one is called.
    # @param context [Blueprinter::V2::Context::Result]
    # @return [String]

    # around_hook: Instrument extension hook calls. MUST yield!
    # @param extension [Blueprinter::Extension] Instance of the extension
    # @param hook [Symbol] Name of hook being called

    # pre_render: Called eary during "render" in V1, this method receives the object to be rendered and
    # may return a modified (or new) object to be rendered.
    # @param object [Object] The object to be rendered
    # @param blueprint [Class] The Blueprinter class
    # @param view [Symbol] The blueprint view
    # @param options [Hash] Options passed to "render"
    # @return [Object] The object to continue rendering
  end
end
