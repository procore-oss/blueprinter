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
      return true if if_callable && !if_callable.call(field_name, object, local_options)

      unless_callable && unless_callable.call(field_name, object, local_options)
    end

    private

    def if_callable
      @_if_callable ||= callable_from(:if)
    end

    def unless_callable
      @_unless_callable ||= callable_from(:unless)
    end

    def callable_from(condition)
      config = Blueprinter.configuration

      # Use field-level callable, or when not defined, try global callable
      tmp = if options.key?(condition)
              options.fetch(condition)
            elsif config.valid_callable?(condition)
              config.public_send(condition)
            end

      return false unless tmp

      case tmp
      when Proc then tmp
      when Symbol then blueprint.method(tmp)
      else
        raise ArgumentError, "#{tmp.class} is passed to :#{condition}"
      end
    end
  end
end
