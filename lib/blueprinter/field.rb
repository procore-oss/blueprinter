# frozen_string_literal: true

# @api private
module Blueprinter
  class Field
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

    def skip?(field_name, object, local_options)
      if Blueprinter.configuration.roll_up_conditions
        any_global_or_field_condition_failed?(field_name, object, local_options)
      else
        return true if if_callable && !if_callable.call(field_name, object, local_options)

        unless_callable && unless_callable.call(field_name, object, local_options)
      end
    end

    private

    def any_global_or_field_condition_failed?(field_name, object, local_options)
      return true if if_callables.any? { |if_call| !if_call.call(field_name, object, local_options) }

      unless_callables.any? { |unless_call| unless_call.call(field_name, object, local_options) }
    end

    def if_callable
      return @if_callable if defined?(@if_callable)

      @if_callable = callable_from(:if)
    end

    def if_callables
      [
        extract_callable_from(Blueprinter.configuration.if),
        extract_callable_from(options[:if])

      ].select { |callable| callable }
    end

    def unless_callable
      return @unless_callable if defined?(@unless_callable)

      @unless_callable = callable_from(:unless)
    end

    def unless_callables
      [
        extract_callable_from(Blueprinter.configuration.unless),
        extract_callable_from(options[:unless])
      ].select { |callable| callable }
    end

    def callable_from(condition)
      config = Blueprinter.configuration

      # Use field-level callable, or when not defined, try global callable
      tmp = if options.key?(condition)
              options.fetch(condition)
            elsif config.valid_callable?(condition)
              config.public_send(condition)
            end

      extract_callable_from(tmp)
    end

    def extract_callable_from(tmp_callable)
      return false unless tmp_callable

      case tmp_callable
      when Proc then tmp_callable
      when Symbol then blueprint.method(tmp_callable)
      else
        raise ArgumentError, "#{tmp_callable.class} is passed to :#{condition}"
      end
    end
  end
end
