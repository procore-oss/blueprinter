# frozen_string_literal: true

require 'blueprinter/extractors/auto_extractor'

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

    # Compiles this field into a closure that writes its rendered value into a result hash.
    #
    # ViewCollection calls this once per field while building its cache. A plain field becomes a
    # Hash#[] or public_send read. Every other field keeps the extractor path. :if/:unless symbols
    # are not resolved here; skip? does that the first time a render includes the field, so a bad
    # symbol on a view that is never rendered does not raise while some other view is compiled.
    #
    # @return [Proc] called with (result_hash, object, options)
    def compile
      simple? ? compile_simple : compile_general
    end

    private

    def if_callable
      @_if_callable ||= callable_from(:if)
    end

    def unless_callable
      @_unless_callable ||= callable_from(:unless)
    end

    # The overwhelmingly common field: read an attribute (or Hash key) and store it. With no
    # conditions, block, datetime format or default in play, none of AutoExtractor's per-call
    # branching is needed.
    def compile_simple
      name = @name
      method = @method

      lambda do |result_hash, object, _options|
        result_hash[name] = object.is_a?(Hash) ? object[method] : object.public_send(method)
      end
    end

    # Everything else goes through the configured extractor.
    def compile_general
      name = @name
      exclude_if_nil = options[:exclude_if_nil]

      lambda do |result_hash, object, options_hash|
        next if skip?(name, object, options_hash)

        value = extract(object, options_hash)
        next if value.nil? && exclude_if_nil

        result_hash[name] = value
      end
    end

    # Whether this field can take the fast path. Associations never qualify: their extractor is an
    # AssociationExtractor, which recurses into another Blueprint.
    def simple?
      extractor.instance_of?(AutoExtractor) && plain_options? && plain_configuration?
    end

    def plain_options?
      !options[:block] && !options[:exclude_if_nil] && !options[:datetime_format] &&
        !options.key?(:default) && !options.key?(:default_if)
    end

    # A global datetime_format or field_default changes the value of every field, and a global
    # :if/:unless adds a per-object condition, so none of those can be skipped.
    #
    # Condition presence is all that is checked. Resolving a Symbol calls blueprint.method, and this
    # runs while every view is compiled, so a bad symbol on an unused view would raise on the first
    # render of any view. skip? resolves the callable when that field is actually rendered.
    def plain_configuration?
      config = Blueprinter.configuration

      config.datetime_format.nil? && config.field_default.nil? &&
        !condition_configured?(:if, config) && !condition_configured?(:unless, config)
    end

    def condition_configured?(condition, config)
      value = options.key?(condition) ? options.fetch(condition) : config.public_send(condition)
      value ? true : false
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
