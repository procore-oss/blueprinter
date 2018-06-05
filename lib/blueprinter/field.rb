# @api private
class Blueprinter::Field
  attr_reader :method, :name, :extractor, :options, :blueprint
  def initialize(method, name, extractor, blueprint, options = {})
    @method = method
    @name = name
    @extractor = extractor
    @blueprint = blueprint
    @options = options
  end

  def extract(object, local_options)
    extractor.extract(method, object, local_options, options)
  end

  def skip?(object, local_options)
    return true if if_callable && !if_callable.call(object, local_options)
    unless_callable && unless_callable.call(object, local_options)
  end

  private

  def if_callable
    return @if_callable unless @if_callable.nil?
    @if_callable ||= callable_from(:if)
  end

  def unless_callable
    return @unless_callable unless @unless_callable.nil?
    @unless_callable ||= callable_from(:unless)
  end

  def callable_from(option_name)
    return false unless options.key?(option_name)

    tmp = options.fetch(option_name)
    case tmp
    when Proc then tmp
    when Symbol then blueprint.method(tmp)
    else
      raise ArgumentError, "#{tmp.class} is passed to :#{option_name}"
    end
  end
end
