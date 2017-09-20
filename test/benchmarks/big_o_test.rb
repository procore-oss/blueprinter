require_relative '../test_helper'
require 'ostruct'
require 'minitest/benchmark'

class PaintedRabbit::BigOTest < Minitest::Benchmark
  def setup
    @painted_rabbit = Class.new(PaintedRabbit::Base) do
      field :id
      field :name
    end
    @prepared_objects = self.class.bench_range.inject({}) do |hash, n|
      hash.merge n => n.times.map {|i| OpenStruct.new(id: i, name: "obj #{i}")}
    end
  end

  def bench_render_basic
    assert_performance_linear do |n|
      @painted_rabbit.render(@prepared_objects[n])
    end
  end
end
