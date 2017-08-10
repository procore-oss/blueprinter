require 'rails_test_helper'
require_relative 'factories/model_factories.rb'

class PaintedRabbit::ActiveRecordTest < ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods

  test 'simple model serializer' do
    SimpleUserSerializer = Class.new(PaintedRabbit::Base) do
      identifier :id
      field :email
      fields :last_name, :first_name
    end

    user = create(:user)

    expected_result = JSON.generate({
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name
    })

    assert_equal(expected_result, SimpleUserSerializer.render(user))
  end

  test 'model serializer with views' do
    ViewUserSerializer = Class.new(PaintedRabbit::Base) do
      identifier :id
      field :email
      fields :last_name, :first_name
    end
  end

end
