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

      include_in :normal do
        fields :last_name, :first_name
      end
    end

    user = create(:user)

    expected_default_view = JSON.generate({
      id: user.id,
      email: user.email
    })
    assert_equal(expected_default_view, ViewUserSerializer.render(user))
    expected_normal_view = JSON.generate({
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name
    })
    assert_equal(expected_normal_view,
                 ViewUserSerializer.render(user, view: :normal))
  end

  test 'model serializer with associations' do
    SimpleVehicleSerializer = Class.new(PaintedRabbit::Base) do
      identifier :id
      fields :make, :model

      include_in :extended do
        field :miles
      end
    end

    UserSerializer = Class.new(PaintedRabbit::Base) do
      identifier :id
      field :email
      fields :last_name, :first_name

      include_in :normal do
        association :vehicles, serializer: SimpleVehicleSerializer
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
    assert_equal(expected_result, UserSerializer.render(user, view: :normal))
  end

  test 'model serializer with associations with views' do
    VehicleViewSerializer = Class.new(PaintedRabbit::Base) do
      identifier :id
      fields :make, :model

      include_in :extended do
        field :miles
      end
    end

    UserAssociationSerializer = Class.new(PaintedRabbit::Base) do
      identifier :id
      field :email
      fields :last_name, :first_name

      include_in :normal do
        association :vehicles, serializer: VehicleViewSerializer, view: :extended
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
    assert_equal(expected_result, UserAssociationSerializer.render(user, view: :normal))
  end
end
