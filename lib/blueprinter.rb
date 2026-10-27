# frozen_string_literal: true

module Blueprinter
  autoload :Base, 'blueprinter/base'
  autoload :BlueprinterError, 'blueprinter/blueprinter_error'
  autoload :Configuration, 'blueprinter/configuration'
  autoload :Deprecation, 'blueprinter/deprecation'
  autoload :Errors, 'blueprinter/errors'
  autoload :Extension, 'blueprinter/extension'
  autoload :Transformer, 'blueprinter/transformer'

  class << self
    # @return [Configuration]
    def configuration
      @_configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    # Resets global configuration.
    #
    # Bumps the generation counter as well: a fresh Configuration starts with the default values,
    # which is itself a configuration change as far as any compiled Blueprint cache is concerned.
    def reset_configuration!
      @_configuration = nil
      Configuration.bump_generation!
    end
  end
end
