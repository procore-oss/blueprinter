class PaintedRabbit::Serializer
  def initialize(block)
    @block = block
  end
  def self.serialize(&block)
    @_blah = self.new(block)
  end

  def self.bleh
    @_blah
  end

  def call(field_name, object, options={})
    @block.call(field_name, object, options)
  end
end
