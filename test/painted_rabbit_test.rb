require 'test_helper'
require 'ostruct'

class PaintedRabbit::Test < Minitest::Test

  def test_truth
    assert_kind_of Module, PaintedRabbit
  end

  def test_templates_class
    my_obj = OpenStruct.new(id: 1, name: 'Meg')
    simple_rabbit = Class.new(PaintedRabbit::Base) do
      field :id
      field :name
    end
    assert_equal('{"id":1,"name":"Meg"}', simple_rabbit.render(my_obj))
  end

  def test_renaming_keys
    my_obj = OpenStruct.new(id: 1, name: 'Meg')
    rename_rabbit = Class.new(PaintedRabbit::Base) do
      field :id, name: :identifier
      field :name
    end
    assert_equal('{"identifier":1,"name":"Meg"}', rename_rabbit.render(my_obj))
  end

  def test_fields_using_custom_serializers
    upcase_serializer = Class.new(PaintedRabbit::Serializer) do
      # TODO: this API sucks, just pass the value.
      # It has a place internally and for complicated uses, but should be wrapped.
      serialize do |field_name, object|
        object.public_send(field_name).upcase
      end
    end
    my_obj = OpenStruct.new(id: 1, name: 'Meg')

    upcase_rabbit = Class.new(PaintedRabbit::Base) do
      field :id
      field :name, serializer: upcase_serializer
    end
    assert_equal('{"id":1,"name":"MEG"}', upcase_rabbit.render(my_obj))
  end

  def test_accepts_array_of_fields
    my_obj = OpenStruct.new(id: 1, name: 'Meg', description: 'A person')
    my_klass = Class.new(PaintedRabbit::Base) do
      identifier :id
      fields :name, :description
    end
    assert_equal('{"id":1,"description":"A person","name":"Meg"}', my_klass.render(my_obj))
  end

  def test_views
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
