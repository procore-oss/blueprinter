require 'activerecord_helper'
require 'benchmark_helper'
require 'blueprinter/base'

class Blueprinter::ActiveRecordIPSTest < Minitest::Test
  include FactoryBot::Syntax::Methods
  include BenchmarkHelper

  def setup
    @blueprinter = Class.new(Blueprinter::Base) do
      fields :first_name, :last_name
    end
    @prepared_objects = 10.times.map {create(:user)}
  end

  def test_render
    result = iterate {@blueprinter.render(@prepared_objects)}
    puts "\nActiveRecord IPS: #{result}"
    assert_operator(result, :>=, 2000)
  end
end
