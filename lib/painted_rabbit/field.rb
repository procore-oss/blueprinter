class PaintedRabbit::Field
  attr_reader :method, :name, :serializer, :options
  def initialize(method, name, serializer, options = {})
    @method = method
    @name = name
    @serializer = serializer
    @options = options
  end
end
