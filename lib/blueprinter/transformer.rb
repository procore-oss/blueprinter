# frozen_string_literal: true

module Blueprinter
  # @api private
  class Transformer
    def transform(_result_hash, _primary_obj, _options = {})
      fail NotImplementedError, 'A Transformer must implement #transform'
    end

    def self.transform(result_hash, primary_obj, options = {})
      self.new.transform(result_hash, primary_obj, options)
    end
  end
end
