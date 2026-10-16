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

    # NOTE: `callable_from` returns `false` when no callable is configured, which is the common case.
    # `||=` therefore never memoizes it, causing a full re-resolution (including a global config
    # lookup) for every field of every object rendered. The `defined?` guard memoizes falsey values
    # too, so resolution happens exactly once per field.
    #
    # As a result, global `config.if`/`config.unless` are read once per field, on first use. Set them
    # before rendering. This matches `config.sort_fields_by`, which is likewise snapshotted when a
    # ViewCollection is built.
    def if_callable
      return @_if_callable if defined?(@_if_callable)

      @_if_callable = callable_from(:if)
    end

    def unless_callable
      return @_unless_callable if defined?(@_unless_callable)

      @_unless_callable = callable_from(:unless)
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
