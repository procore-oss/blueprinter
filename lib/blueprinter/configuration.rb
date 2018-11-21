module Blueprinter
  class Configuration
    attr_accessor :generator, :method, :sort_by_definition

    def initialize
      @generator = JSON
      @method = :generate
      @sort_by_definition = false
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
