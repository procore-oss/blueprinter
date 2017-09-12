module PaintedRabbit
  class View
    attr_reader :fields, :included_views, :excluded_fields

    def initialize
      @fields = []
      @included_views = []
      @excluded_fields = []
    end

    def <<(field)
      @fields << field
    end
  end
end
