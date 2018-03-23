# @api private
class Blueprinter::Field
  attr_reader :method, :name, :extractor, :options
  def initialize(method, name, extractor, options = {})
    @method = method
    @name = name
    @extractor = extractor
    @options = options
  end

  def extract(object, local_options)
    extractor.extract(method, object, local_options, options)
  end
end
