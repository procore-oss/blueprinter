# frozen_string_literal: true

module Blueprinter
  autoload :Base, 'blueprinter/base'
  autoload :BlueprinterError, 'blueprinter/blueprinter_error'
  autoload :Configuration, 'blueprinter/configuration'
  autoload :Deprecation, 'blueprinter/deprecation'
  autoload :Errors, 'blueprinter/errors'
  autoload :Extension, 'blueprinter/extension'
  autoload :Hooks, 'blueprinter/hooks'
  autoload :Transformer, 'blueprinter/transformer'
  autoload :V2, 'blueprinter/v2'

  class << self
    # @return [Configuration]
    def configuration
      @_configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    # Resets global configuration.
    def reset_configuration!
      @_configuration = nil
    end
  end
end
