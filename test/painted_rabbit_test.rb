require 'test_helper'
require 'ostruct'
class PaintedRabbit::Test < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, PaintedRabbit
  end

  test "it renders based on a templates class" do
    my_obj = OpenStruct.new(id: 1, name: 'Meg')
    SimpleRabbit = Class.new(PaintedRabbit::Base) do
      field :id
      field :name
    end
    assert_equal('{"id":1,"name":"Meg"}', SimpleRabbit.render(my_obj))
  end

  test "it can rename keys" do
    my_obj = OpenStruct.new(id: 1, name: 'Meg')
    RenameRabbit = Class.new(PaintedRabbit::Base) do
      field :id, name: :identifier
      field :name
    end
    assert_equal('{"identifier":1,"name":"Meg"}', RenameRabbit.render(my_obj))
  end

  test "fields can use custom serializers" do
    UpcaseSerializer = Class.new(PaintedRabbit::Serializer) do
      # TODO: this API sucks, just pass the value.
      # It has a place internally and for complicated uses, but should be wrapped.
      serialize do |field_name, object|
        object.public_send(field_name).upcase
      end
    end
    my_obj = OpenStruct.new(id: 1, name: 'Meg')

    UpcaseRabbit = Class.new(PaintedRabbit::Base) do
      field :id
      field :name, serializer: UpcaseSerializer
    end
    assert_equal('{"id":1,"name":"MEG"}', UpcaseRabbit.render(my_obj))
  end

  test "it can take an array of fields" do
    my_obj = OpenStruct.new(id: 1, name: 'Meg', description: 'A person')
    my_klass = Class.new(PaintedRabbit::Base) do
      identifier :id
      fields :name, :description
    end
    assert_equal('{"id":1,"description":"A person","name":"Meg"}', my_klass.render(my_obj))
  end

  test "it supports views" do
    my_obj = OpenStruct.new(id: 1, name: 'Meg', position: 'Manager', description: 'A person', 'company': 'Procore')
    view_klass = Class.new(PaintedRabbit::Base) do
      identifier :id
      include_in [:normal, :extended] do
        fields :name, :position
        field :company, name: :employer
      end
      include_in :extended do
        field :description
      end
    end
    assert_equal('{"id":1}', view_klass.render(my_obj))
    assert_equal('{"id":1,"employer":"Procore","name":"Meg","position":"Manager"}', view_klass.render(my_obj, view: :normal))
    assert_equal('{"id":1,"description":"A person","employer":"Procore","name":"Meg","position":"Manager"}', view_klass.render(my_obj, view: :extended))
  end
end
