module Blueprinter
  # @api private
  class Mapper < SimpleDelegator

    def initialize(object, options = {})
      super(object)
      @options = options
    end


    attr_reader :options

    alias_method :object, :__getobj__

  end
end
