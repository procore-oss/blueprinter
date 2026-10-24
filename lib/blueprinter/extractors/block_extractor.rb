# frozen_string_literal: true

require 'blueprinter/extractor'

module Blueprinter
  # @api private
  class BlockExtractor < Extractor
    def extract(_field_name, object, local_options, options = {})
      block = options[:block]

      # Symbol#to_proc blocks forward every argument to the method, so block.call(object, **local_options)
      # would become object.method_name(**local_options), which most methods don't accept. They get only
      # the object; regular blocks get the object and local_options.
      if symbol_to_proc?(block)
        block.call(object)
      else
        block.call(object, **local_options)
      end
    end

    private

    # Symbol#to_proc is a native lambda taking (obj, *args): a lambda with arity -2 and no Ruby source
    # location. Plain DSL blocks are never lambdas, so they fail the first check without allocating;
    # only a user lambda with arity -2 reaches source_location, which builds a [file, line] array.
    def symbol_to_proc?(block)
      block.lambda? && block.arity == -2 && block.source_location.nil?
    end
  end
end
