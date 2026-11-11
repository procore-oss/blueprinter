# frozen_string_literal: true

require 'benchmark_helper'
require 'blueprinter'
require 'ostruct'

class Blueprinter::BigOTest < Minitest::Benchmark
  include BenchmarkHelper

  def self.bench_range = bench_linear(1_000, 10_000, 1_000)

  def setup
    @blueprinter = Class.new(Blueprinter::Base) do
      field :id
      field :name
    end
    @objects = 10_000.times.map {|i| OpenStruct.new(id: i, name: "obj #{i}")}
  end

  def bench_render_basic
    assert_scales_linearly do |n|
      @blueprinter.render(@objects.first(n))
    end
  end
end
