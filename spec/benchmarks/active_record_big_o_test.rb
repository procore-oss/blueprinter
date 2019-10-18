require 'activerecord_helper'
require 'benchmark_helper'
require 'blueprinter/base'

class Blueprinter::ActiveRecordBigOTest < Minitest::Benchmark
  include FactoryBot::Syntax::Methods

  def setup
    @blueprinter = Class.new(Blueprinter::Base) do
      identifier :id
      fields :first_name, :last_name
    end
    @prepared_objects = self.class.bench_range.inject({}) do |hash, n|
      hash.merge n => n.times.map { create(:user) }
    end
  end

  def bench_render_active_record
    assert_performance_linear do |n|
      @blueprinter.render(@prepared_objects[n])
    end
  end
end
