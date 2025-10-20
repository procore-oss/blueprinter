# frozen_string_literal: true

module Blueprinter
  #
  # Base class for all extensions.
  #
  # V2 hook call order:
  #
  # - around_hook (called around any other extension hook)
  # - around_result
  #   - around_blueprint_init
  #     - around_serialize_object | around_serialize_collection
  #       - around_blueprint
  #         - around_field_value | around_object_value | around_collection_value
  #           - around_blueprint_init …
  #
  # V1 hook call order:
  #  - pre_render
  #
  class Extension
    include V2::Helpers

    HOOKS = %i[
      around_hook
      around_result
      around_blueprint_init
      around_serialize_object
      around_serialize_collection
      around_blueprint
      around_field_value
      around_object_value
      around_collection_value
      pre_render
    ].freeze

    # @return [Array<Symbol>] The names of the hooks implemented in this extension
    def self.hooks
      @_hooks ||= (public_instance_methods(true) & HOOKS).freeze
    end

    # If this returns true, around_hook will not be called when this extension's hooks are run. Used by core extensions.
    def hidden? = false

    # around_result TODO
    # @param context [Blueprinter::V2::Context::Result]

    # around_serialize_object: Runs around serialization of a Blueprint object.
    # @param context [Blueprinter::V2::Context::Object]

    # around_serialize_collection: Runs around serialization of a Blueprint collection.
    # @param context [Blueprinter::V2::Context::Object]

    # around_blueprint: Runs around serialization of every Blueprint.
    # @param context [Blueprinter::V2::Context::Object]

    # around_field_value TODO

    # around_object_value TODO

    # around_collection_value TODO

    # blueprint_fields: Returns the fields that should be included in the correct order. Default is all fields in the order
    # in which they were defined.
    # NOTE If there are multiple blueprint_fields hooks, only the last one is called.
    # NOTE Only runs once per Blueprint per render.
    # @param context [Blueprinter::V2::Context::Render]
    # @return [Array<Blueprinter::V2::Fields::Field|Blueprinter::V2::Fields::Object|Blueprinter::V2::Fields::Collection>]

    # blueprint_setup: Called once per blueprint per render. A common use is to pre-calculate certain options
    # and cache them in context.data, so we don't have to recalculate them for every field.
    # @param context [Blueprinter::V2::Context::Render]

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

    private

    # Helper for around_result hooks to declare that a result is "final"
    def final(val) = V2::Context::Final.new(val)

    # Helper for around_result hooks to check if a previous hook has declared a result "final"
    def final?(val) = val.is_a? V2::Context::Final
  end
end
