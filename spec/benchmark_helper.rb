require 'minitest/autorun'
require 'minitest/benchmark'

module BenchmarkHelper
  def iterate
    start = Time.now
    count = 0
    while Time.now - start <= 1 do
      yield
      count += 1
    end
    count
  end
end
