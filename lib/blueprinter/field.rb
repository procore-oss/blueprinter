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

  def skip?(object, field_name, local_options)
    return true if if_callable && !if_callable.call(object, field_name, local_options)
    unless_callable && unless_callable.call(object, field_name, local_options)
  end

  private

  def if_callable
    return @if_callable if defined?(@if_callable)
    @if_callable = callable_from(:if)
  end

  def unless_callable
    return @unless_callable if defined?(@unless_callable)
    @unless_callable = callable_from(:unless)
  end

  def callable_from(option_name)
    config = Blueprinter.configuration

    # Use field-level callable, or when not defined, try global callable
    tmp = if options.key?(option_name)
      options.fetch(option_name)
    elsif config.valid_callable?(option_name)
      config.public_send(option_name)
    end

    return false unless tmp

    case tmp
    when Proc then tmp
    when Symbol then blueprint.method(tmp)
    else
      raise ArgumentError, "#{tmp.class} is passed to :#{option_name}"
    end
  end
end
