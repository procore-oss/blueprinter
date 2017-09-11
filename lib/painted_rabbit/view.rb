module PaintedRabbit
  class View
    attr_reader :fields

    def initialize
      @fields = []
    end

    def <<(field)
      @fields << field
    end

  end
end
