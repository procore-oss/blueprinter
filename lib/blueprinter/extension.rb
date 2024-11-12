# frozen_string_literal: true

module Blueprinter
  #
  # Base class for all extensions.
  #
  # V2 hook call order:
  #  - collection? (skipped if calling render_object/render_collection)
  #  - input_object | input_collection
  #  - prepare
  #  - blueprint_fields
  #  - blueprint_input
  #  - field_value
  #  - exclude_field?
  #  - object_value
  #  - exclude_object?
  #  - collection_value
  #  - exclude_collection?
  #  - blueprint_output
  #  - output_object | output_collection
  #
  # V1 hook call order:
  #  - pre_render
  #
  class Extension
    #
    # Returns true if the given object should be treated as a collection (i.e. supports `map { |obj| ... }`).
    #
    # @param [Object]
    # @return [Boolean]
    #
    def collection?(_object)
      false
    end

    #
    # Called once per blueprint per render. A common use is to pre-calculate certain options
    # and cache them in context.data, so we don't have to recalculate them for every field.
    #
    # @param context [Blueprinter::V2::Context]
    #
    def prepare(context); end

    #
    # Returns the fields that should be included in the correct order. Default is all fields in the order in which they were defined.
    #
    # NOTE Only runs once per Blueprint per render.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Array<Blueprinter::V2::Field|Blueprinter::V2::Object|Blueprinter::V2::Collection>]
    #
    def blueprint_fields(ctx)
      []
    end

    #
    # Modify or replace the object passed to render/render_object.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def input_object(context)
      context.object
    end

    #
    # Modify or replace the collection passed to render/render_collection.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def input_collection(context)
      context.object
    end

    #
    # Modify or replace the object result before final render (e.g. to JSON).
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def output_object(context)
      context.value
    end

    #
    # Modify or replace the collection result before final render (e.g. to JSON).
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def output_collection(context)
      context.value
    end

    #
    # Modify or replace an object right before it's serialized by a Blueprint.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def blueprint_input(context)
      context.object
    end

    #
    # Modify or replace the serialized output from any Blueprint.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def blueprint_output(context)
      context.value
    end

    #
    # Modify or replace the value used for the field.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def field_value(context)
      context.value
    end

    #
    # Modify or replace the value used for the object.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def object_value(context)
      context.value
    end

    #
    # Modify or replace the value used for the collection.
    #
    # @param context [Blueprinter::V2::Context]
    # @return [Object]
    #
    def collection_value(context)
      context.value
    end

    #
    # Return true to exclude this field from the result.
    #
    # @param _context [Blueprinter::V2::Context]
    # @return [Boolean]
    #
    def exclude_field?(_context)
      false
    end

    #
    # Return true to exclude this object from the result.
    #
    # @param _context [Blueprinter::V2::Context]
    # @return [Boolean]
    #
    def exclude_object?(_context)
      false
    end

    #
    # Return true to exclude this collection from the result.
    #
    # @param _context [Blueprinter::V2::Context]
    # @return [Boolean]
    #
    def exclude_collection?(_context)
      false
    end

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
