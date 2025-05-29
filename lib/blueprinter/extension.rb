# frozen_string_literal: true

module Blueprinter
  #
  # Base class for all extensions.
  #
  # V2 hook call order:
  #  - around_hook (called around any other extension hook)
  #  - around_object_render | around_collection_render
  #    - input_object | input_collection
  #    - around_object_serialization | around_collection_serialization
  #      - blueprint_fields (only first time during a given render)
  #      - prepare (only first time during a given render)
  #      - blueprint_input
  #      - extract_value
  #      - field_value
  #      - exclude_field?
  #      - object_value
  #      - exclude_object?
  #      - collection_value
  #      - exclude_collection?
  #      - blueprint_output
  #    - output_object | output_collection
  #    - json
  #
  # V1 hook call order:
  #  - pre_render
  #
  class Extension
    HOOKS = %i[
      around_hook
      around_object_render
      around_collection_render
      input_object
      input_collection
      around_object_serialization
      around_collection_serialization
      blueprint_fields
      prepare
      blueprint_input
      extract_value
      field_value
      exclude_field?
      object_value
      exclude_object?
      collection_value
      exclude_collection?
      blueprint_output
      output_object
      output_collection
      json
      pre_render
    ].freeze

    # If this returns true, around_hook will not be called when this extension's hooks are run. Used by core extensions.
    def hidden? = false

    # around_object_render: Runs around the entire rendering process for an object. MUST yield!
    # @param context [Blueprinter::V2::Context::Object]

    # around_collection_render: Runs around the entire rendering process for a collection. MUST yield!
    # @param context [Blueprinter::V2::Context::Object]

    # around_object_serialization: Runs around serialization of a Blueprint object. Surrounds the `prepare` through
    # `blueprint_output` hooks. MUST yield!
    # @param context [Blueprinter::V2::Context::Object]

    # around_collection_serialization: Runs around serialization of a Blueprint collection. Surrounds the `prepare` through
    # `blueprint_output` hooks. MUST yield!
    # @param context [Blueprinter::V2::Context::Object]

    # prepare: Called once per blueprint per render. A common use is to pre-calculate certain options
    # and cache them in context.data, so we don't have to recalculate them for every field.
    # @param context [Blueprinter::V2::Context::Render]

    # blueprint_fields: Returns the fields that should be included in the correct order. Default is all fields in the order
    # in which they were defined.
    # NOTE If there are multiple blueprint_fields hooks, only the last one is called.
    # NOTE Only runs once per Blueprint per render.
    # @param context [Blueprinter::V2::Context::Render]
    # @return [Array<Blueprinter::V2::Fields::Field|Blueprinter::V2::Fields::Object|Blueprinter::V2::Fields::Collection>]

    # input_object: Modify or replace the object passed to render/render_object. The returned object is what will be
    # rendered.
    # @param context [Blueprinter::V2::Context::Object]
    # @return [Object]

    # input_collection: Modify or replace the collection passed to render/render_collection. The returned collection is what
    # will be rendered.
    # @param context [Blueprinter::V2::Context::Object]
    # @return [Object]

    # output_object: Modify or replace the object result (stored in context.value) before final render (e.g. to JSON). The
    # returned object is what will be rendered.
    # @param context [Blueprinter::V2::Context::Result]
    # @return [Object]

    # output_collection: Modify or replace the collection result (stored in context.value) before final render (e.g. to
    # JSON). The returned object is what will be rendered.
    # @param context [Blueprinter::V2::Context::Result]
    # @return [Object]

    # blueprint_input: Modify or replace an object right before it's serialized by a Blueprint. The returned object will be
    # used as the input to the Blueprint.
    # @param context [Blueprinter::V2::Context::Object]
    # @return [Object]

    # blueprint_output: Modify or replace the serialized output from any Blueprint. The returned object will be used as the
    # output of the Blueprint.
    # @param context [Blueprinter::V2::Context::Result]
    # @return [Object]

    # extract_value: Extract a field, objecet, or collection value from an object. The returned value will be run through the
    # NOTE If there are multiple extract_value hooks, only the last one is called.
    # field_value, object_value, or collection_value hooks.

    # field_value: Modify or replace the value used for the field. The returned value will be run through any formatters and
    # used as the field's value.
    # @param context [Blueprinter::V2::Context::Field]
    # @return [Object]

    # object_value: Modify or replace the value used for the object. The returned value will be used as the input for the
    # object's Blueprint.
    # @param context [Blueprinter::V2::Context::Field]
    # @return [Object]

    # collection_value: Modify or replace the value used for the collection. The returned value will be used as the input for
    # the collection's Blueprint.
    # @param context [Blueprinter::V2::Context::Field]
    # @return [Object]

    # exclude_field?: Return true to exclude this field from the result.
    # @param context [Blueprinter::V2::Context::Field]
    # @return [Boolean]

    # exclude_object?: Return true to exclude this object from the result.
    # @param context [Blueprinter::V2::Context::Field]
    # @return [Boolean]

    # exclude_collection?: Return true to exclude this collection from the result.
    # @param context [Blueprinter::V2::Context::Field]
    # @return [Boolean]

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
