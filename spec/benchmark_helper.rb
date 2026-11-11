# frozen_string_literal: true

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

  # Fits the fastest of several timings per size to a * n^b and asserts b stays below max_exponent.
  # The minimum ignores a single stalled sample, and the exponent separates n from n^2, which an
  # R^2 on a linear fit over 1..10,000 can't.
  def assert_scales_linearly(max_exponent: 1.3, samples: 5, &work)
    sizes = self.class.bench_range
    times = sizes.map do |n|
      Array.new(samples) do
        GC.start
        t0 = Minitest.clock_time
        work.call(n)
        Minitest.clock_time - t0
      end.min
    end
    io.puts "#{name}\t#{times.map { |t| format('%9.6f', t) }.join("\t")}"
    exponent = fit_power(sizes, times)[1]
    assert_operator exponent, :<, max_exponent, "render time grows as n^#{exponent.round(2)}"
  end
end
