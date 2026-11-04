# frozen_string_literal: true

require 'activerecord_helper'
require 'benchmark_helper'
require 'blueprinter'

class Blueprinter::ActiveRecordBigOTest < Minitest::Benchmark
  include BenchmarkHelper
  include FactoryBot::Syntax::Methods

  def self.bench_range = bench_linear(1_000, 10_000, 1_000)

  def setup
    @blueprinter = Class.new(Blueprinter::Base) do
      identifier :id
      fields :first_name, :last_name
    end
    @users = 10_000.times.map { create(:user) }
  end

  def bench_render_active_record
    assert_scales_linearly do |n|
      @blueprinter.render(@users.first(n))
    end
  end
end
