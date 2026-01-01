# frozen_string_literal: true

require 'blueprinter/extractor'

module Blueprinter
  # @api private
  class BlockExtractor < Extractor
    # @param object [Object] The object in which the block is called with
    # @param local_options [Hash] The local options to pass to the block
    def extract(_field_name, object, local_options, options = {})
      block = options[:block]

      # Symbol#to_proc creates procs with signature [[:req], [:rest]]
      # These procs forward ALL arguments to the method, which causes
      # issues when we call block.call(object, local_options) because
      # it becomes object.method_name(local_options), and most methods
      # don't accept extra arguments.
      #
      # For Symbol#to_proc, we only pass the object.
      # For regular blocks, we pass both object and local_options.
      if symbol_to_proc?(block)
        block.call(object)
      else
        block.call(object, local_options)
      end
    end

    private

    def symbol_to_proc?(block)
      # Symbol#to_proc has a characteristic signature:
      # - Parameters: [[:req], [:rest]] (one required + rest args)
      # - This is different from regular blocks which typically have
      #   optional parameters like [[:opt, :obj], [:opt, :options]]
      block.parameters == [[:req], [:rest]]
    end
  end
end
