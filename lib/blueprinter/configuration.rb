module Blueprinter
  class Configuration
    attr_accessor :generator, :method

    def initialize
      @generator = JSON
      @method = :generate
    end

    def jsonify(blob)
      generator.public_send(method, blob)
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration if block_given?
  end
end
