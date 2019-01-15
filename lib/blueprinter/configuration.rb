module Blueprinter
  class Configuration
    attr_accessor :generator, :if, :method, :sort_fields_by, :unless

    def initialize
      @generator = JSON
      @if = nil
      @method = :generate
      @sort_fields_by = :name_asc
      @unless = nil
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
