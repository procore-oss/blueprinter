# frozen_string_literal: true

module Blueprinter
  #
  # Base class for all extensions.
  #
  # V2 hook call order:
  #  - collection? (skipped if calling render_object/render_collection)
  #  - around
  #    - input_object | input_collection
  #    - around_object | around_collection
  #      - prepare (only first time during a given render)
  #      - blueprint_fields (only first time during a given render)
  #      - blueprint_input
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
    #
    # Returns true if the given object should be treated as a collection (i.e. supports `map { |obj| ... }`).
    #
    # @param _object [Object]
    # @return [Boolean]
    #
    def collection?(_object) = false

    #
    # Runs around the entire rendering process. MUST yield!
    #
    # @param _context [Blueprinter::V2::Context]
    #
    def around(_context) = yield

    #
    # Runs around serialization of a Blueprint object. Surrounds the `prepare` through `blueprint_output` hooks. MUST yield!
    #
    # @param _context [Blueprinter::V2::Context]
    #
    def around_object(_context) = yield

    #
    # Runs around serialization of a Blueprint collection. Surrounds the `prepare` through `blueprint_output` hooks. MUST yield!
    #
    # @param _context [Blueprinter::V2::Context]
    #
    def around_collection(_context) = yield

    #
    # Called once per blueprint per render. A common use is to pre-calculate certain options
    # and cache them in context.data, so we don't have to recalculate them for every field.
    #
    # @param _context [Blueprinter::V2::Context]
    #
    def prepare(_context) = nil

    #
    # Returns the fields that should be included in the correct order. Default is all fields in the order in which they were defined.
    #
    # NOTE Only runs once per Blueprint per render.
    #
    # @param _context [Blueprinter::V2::Context]
    # @return [Array<Blueprinter::V2::Field|Blueprinter::V2::Object|Blueprinter::V2::Collection>]
    #
    def blueprint_fields(_context) = []

    #
    # Modify or replace the object passed to render/render_object. The returned object is what will be rendered.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def input_object(context) = context.object

    #
    # Modify or replace the collection passed to render/render_collection. The returned collection is what will be rendered.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def input_collection(context) = context.object

    #
    # Modify or replace the object result (stored in context.value) before final render (e.g. to JSON). The returned object is what will be rendered.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def output_object(context) = context.value

    #
    # Modify or replace the collection result (stored in context.value) before final render (e.g. to JSON). The returned object is what will be rendered.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def output_collection(context) = context.value

    #
    # Modify or replace an object right before it's serialized by a Blueprint. The returned object will be used as the input to the Blueprint.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def blueprint_input(context) = context.object

    #
    # Modify or replace the serialized output from any Blueprint. The returned object will be used as the output of the Blueprint.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def blueprint_output(context) = context.value

    #
    # Modify or replace the value used for the field. The returned value will be run through any formatters and used as the field's value.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def field_value(context) = context.value

    #
    # Modify or replace the value used for the object. The returned value will be used as the input for the object's Blueprint.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def object_value(context) = context.value

    #
    # Modify or replace the value used for the collection. The returned value will be used as the input for the collection's Blueprint.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def collection_value(context) = context.value

    #
    # Return true to exclude this field from the result.
    #
    # @param _context [Blueprinter::V2::Context]
    # @return [Boolean]
    #
    def exclude_field?(_context) = false

    #
    # Return true to exclude this object from the result.
    #
    # @param _context [Blueprinter::V2::Context]
    # @return [Boolean]
    #
    def exclude_object?(_context) = false

    #
    # Return true to exclude this collection from the result.
    #
    # @param _context [Blueprinter::V2::Context]
    # @return [Boolean]
    #
    def exclude_collection?(_context) = false

    #
    # Override the default JSON encoder. The returned string will be the JSON output.
    #
    # @param _context [Blueprinter::V2::Context]
    # @return [String]
    #
    def json(_context) = nil

    #
    # Called eary during "render" in V1, this method receives the object to be rendered and
    # may return a modified (or new) object to be rendered.
    #
    # @param object [Object] The object to be rendered
    # @param _blueprint [Class] The Blueprinter class
    # @param _view [Symbol] The blueprint view
    # @param _options [Hash] Options passed to "render"
    # @return [Object] The object to continue rendering
    #
    def pre_render(object, _blueprint, _view, _options)
      object
    end
  end
end
