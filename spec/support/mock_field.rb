# frozen_string_literal: true

class MockField
  attr_reader :name, :method
  def initialize(method, name = nil)
    @method = method
    @name = name || method
  end
end
