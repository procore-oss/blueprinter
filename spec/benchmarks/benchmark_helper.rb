require "rails/test_help"

Rails::TestUnitReporter.executable = 'bin/test'

module BenchmarkHelper
  def iterate(&block)
    start = Time.now
    count = 0
    while Time.now - start <= 1.second do
      yield
      count += 1
    end
    count
  end
end
