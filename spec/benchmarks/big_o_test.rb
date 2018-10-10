require 'ostruct'
require 'minitest/benchmark'

class Blueprinter::BigOTest < Minitest::Benchmark
  def setup
    @blueprinter = Class.new(Blueprinter::Base) do
      field :id
      field :name
    end
    @prepared_objects = self.class.bench_range.inject({}) do |hash, n|
      hash.merge n => n.times.map {|i| OpenStruct.new(id: i, name: "obj #{i}")}
    end
  end

  def bench_render_basic
    assert_performance_linear(0.98) do |n|
      @blueprinter.render(@prepared_objects[n])
    end
  end
end
