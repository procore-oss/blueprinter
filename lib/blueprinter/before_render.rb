# @api private
module Blueprinter
  class BeforeRender
    attr_reader :block
    
    def initialize(block)
      @block = block
    end

    def call(object, options)
      block.call(object, options)
    end
  end
end
