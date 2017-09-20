require_relative '../rails_test_helper'
require_relative '../factories/model_factories.rb'
require_relative 'benchmark_helper'

class PaintedRabbit::ActiveRecordIPSTest < Minitest::Test
  include FactoryGirl::Syntax::Methods
  include BenchmarkHelper

  def setup
    @painted_rabbit = Class.new(PaintedRabbit::Base) do
      fields :first_name, :last_name
    end
    @prepared_objects = 10.times.map {create(:user)}
  end

  def test_render
    result = iterate {@painted_rabbit.render(@prepared_objects)}
    puts "\nActiveRecord IPS: #{result}"
    assert_operator(result, :>=, 2500)
  end
end
