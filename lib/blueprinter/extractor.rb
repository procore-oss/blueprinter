# frozen_string_literal: true

module Blueprinter
  # The default extractor and base class for custom V2 extractors
  class Extractor
    # Field extraction for V2
    # @param ctx [Blueprinter::V2::Context]
    def field(ctx)
      if ctx.object.is_a? Hash
        ctx.object[ctx.field.from] || ctx.object[ctx.field.from_str]
      else
        ctx.object.public_send(ctx.field.from)
      end
    end

    # Object extraction for V2
    # @param ctx [Blueprinter::V2::Context]
    def object(ctx)
      field ctx
    end

    # Collection extraction for V2
    # @param ctx [Blueprinter::V2::Context]
    def collection(ctx)
      field ctx
    end

    # V1 extraction
    def extract(_field_name, _object, _local_options, _options = {})
      raise NotImplementedError, 'An Extractor must implement #extract'
    end

    # V1 extraction
    def self.extract(field_name, object, local_options, options = {})
      new.extract(field_name, object, local_options, options)
    end
  end
end
