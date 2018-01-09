# @api private
class Blueprinter::Field
  attr_reader :method, :name, :serializer, :options
  def initialize(method, name, serializer, options = {})
    @method = method
    @name = name
    @serializer = serializer
    @options = options
  end

  def serialize(object, local_options)
    serializer.serialize(method, object, local_options, options)
  end
end
