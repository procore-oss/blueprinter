# frozen_string_literal: true

module Blueprinter
  module V2
    #
    # Base class for extensions.
    #
    # Hook call order:
    #  - input
    #  - field_value
    #  - formatters
    #  - exclude_field?
    #  - object_value
    #  - exclude_object?
    #  - collection_value
    #  - exclude_collection?
    #  - output
    #
    class Extension
      class << self
        attr_accessor :formatters
      end

      def self.inherited(ext)
        ext.formatters = {}
      end

      #
      # Add a formatter for instances of the given class.
      #
      # Example:
      #   class MyExtension < Blueprinter::V2::Extension
      #     format(Time) { |context| context.value.iso8601 }
      #     format Date, :date_str
      #
      #     def date_str(context)
      #       context.value.iso8601
      #     end
      #   end
      #
      # @param klass [Class] The class of objects to format
      # @param formatter_method [Symbol] Name of a public instance method to call for formatting
      # @yield Do formatting in the block instead
      #
      def self.format(klass, formatter_method = nil, &formatter_block)
        formatters[klass] = formatter_method || formatter_block
      end

      #
      # Return true to exclude this field from the result.
      #
      # @param _context [Blueprinter::V2::Serializer::Context]
      # @return [Boolean]
      def exclude_field?(_context)
        false
      end

      #
      # Return true to exclude this object from the result.
      #
      # @param _context [Blueprinter::V2::Serializer::Context]
      # @return [Boolean]
      def exclude_object?(_context)
        false
      end

      #
      # Return true to exclude this collection from the result.
      #
      # @param _context [Blueprinter::V2::Serializer::Context]
      # @return [Boolean]
      def exclude_collection?(_context)
        false
      end

      #
      # Modify or replace the value used for the field.
      #
      # @param context [Blueprinter::V2::Serializer::Context]
      # @return [Object]
      def field_value(context)
        context.value
      end

      #
      # Modify or replace the value used for the object.
      #
      # @param context [Blueprinter::V2::Serializer::Context]
      # @return [Object]
      def object_value(context)
        context.value
      end

      #
      # Modify or replace the value used for the collection.
      #
      # @param context [Blueprinter::V2::Serializer::Context]
      # @return [Object]
      def collection_value(context)
        context.value
      end

      # Modify or replace the object passed to render/render_object/render_collection
      def input(_blueprint, object, _options)
        object
      end

      # Modify or replace the result before final render (e.g. to JSON)
      def output(_blueprint, result, _options)
        result
      end
    end
  end
end
