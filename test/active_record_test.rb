require_relative 'rails_test_helper'
require_relative 'factories/model_factories.rb'

class PaintedRabbit::ActiveRecordTest < ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods

  test 'simple model serializer' do
    simple_user_serializer_class = Class.new(PaintedRabbit::Base) do
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

    assert_equal(expected_result, simple_user_serializer_class.render(user))
  end

  test 'model serializer with views' do
    view_user_serializer_class = Class.new(PaintedRabbit::Base) do
      identifier :id
      field :email

      view :normal do
        fields :last_name, :first_name
      end
    end

    user = create(:user)

    expected_default_view = JSON.generate({
      id: user.id,
      email: user.email
    })
    expected_normal_view = JSON.generate({
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name
    })

    assert_equal(expected_default_view, view_user_serializer_class.render(user))
    assert_equal(expected_normal_view,
                 view_user_serializer_class.render(user, view: :normal))
  end

  test 'model serializer with associations' do
    simple_vehicle_serializer_class = Class.new(PaintedRabbit::Base) do
      identifier :id
      fields :make, :model

      view :extended do
        field :miles
      end
    end

    user_serializer_class = Class.new(PaintedRabbit::Base) do
      identifier :id
      field :email
      fields :last_name, :first_name

      view :normal do
        association :vehicles, serializer: simple_vehicle_serializer_class
      end
    end

    user = create(:user)
    vehicle = create(:vehicle, user: user)

    expected_result = JSON.generate({
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      vehicles: [ {
        id: vehicle.id,
        make: vehicle.make,
        model: vehicle.model
      }]
    })
    assert_equal(expected_result, user_serializer_class.render(user, view: :normal))
  end

  test 'model serializer with associations with views' do
    vehicle_view_serializer_class = Class.new(PaintedRabbit::Base) do
      identifier :id
      fields :make, :model

      view :extended do
        field :miles
      end
    end

    user_association_serializer_class = Class.new(PaintedRabbit::Base) do
      identifier :id
      field :email
      fields :last_name, :first_name

      view :normal do
        association :vehicles, serializer: vehicle_view_serializer_class, view: :extended
      end
    end

    user = create(:user)
    vehicle = create(:vehicle, user: user)

    expected_result = JSON.generate({
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      vehicles: [ {
        id: vehicle.id,
        make: vehicle.make,
        miles: vehicle.miles,
        model: vehicle.model
      }]
    })
    assert_equal(expected_result, user_association_serializer_class.render(user, view: :normal))
  end
end
