module Blueprinter
  class Configuration
    attr_accessor :generator, :method, :sort_fields_by

    def initialize
      @generator = JSON
      @method = :generate
      @sort_fields_by = :name_asc
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
