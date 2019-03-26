module Blueprinter
  class Configuration
    attr_accessor :association_default, :field_default, :generator, :if, :method, :sort_fields_by, :unless

    VALID_CALLABLES = %i(if unless).freeze

    def initialize
      @association_default = nil
      @field_default = nil
      @generator = JSON
      @if = nil
      @method = :generate
      @sort_fields_by = :name_asc
      @unless = nil
      @utc = false
    end

    def jsonify(blob)
      generator.public_send(method, blob)
    end

    def valid_callable?(callable_name)
      VALID_CALLABLES.include?(callable_name)
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration if block_given?
  end
end
