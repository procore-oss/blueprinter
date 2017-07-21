require 'test_helper'
require 'ostruct'
class PaintedRabbit::Test < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, PaintedRabbit
  end

  test "it renders based on a templates class" do
    my_obj = OpenStruct.new(id: 1, name: 'Meg')
    SimpleRabbit = Class.new(PaintedRabbit::Base) do
      attribute :id
      attribute :name
    end
    assert_equal('{"id":1,"name":"Meg"}', SimpleRabbit.render(my_obj))
  end

  test "it can rename keys" do
    my_obj = OpenStruct.new(id: 1, name: 'Meg')
    RenameRabbit = Class.new(PaintedRabbit::Base) do
      attribute :id, name: :identifier
      attribute :name
    end
    assert_equal('{"identifier":1,"name":"Meg"}', RenameRabbit.render(my_obj))
  end

  test "attributes can use custom serializers" do
    UpcaseSerializer = Class.new(PaintedRabbit::Serializer) do
      # TODO: this API sucks, just pass the value.
      # It has a place internally and for complicated uses, but should be wrapped.
      serialize do |attribute_name, object|
        object.public_send(attribute_name).upcase
      end
    end
    my_obj = OpenStruct.new(id: 1, name: 'Meg')

    UpcaseRabbit = Class.new(PaintedRabbit::Base) do
      attribute :id
      attribute :name, serializer: UpcaseSerializer
    end
    assert_equal('{"id":1,"name":"MEG"}', UpcaseRabbit.render(my_obj))
  end
end
