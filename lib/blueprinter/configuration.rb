module Blueprinter
  class Configuration
    attr_accessor :generator

    def initialize
      @generator = JSON
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration if block_given?
  end
end
