require_relative 'test_helper'
require 'ostruct'

class Blueprinter::Test < Minitest::Test

  def test_truth
    assert_kind_of Module, Blueprinter
  end

  def test_templates_class
    my_obj = OpenStruct.new(id: 1, name: 'Meg')
    simple_blueprinter_class = Class.new(Blueprinter::Base) do
      field :id
      field :name
    end
    assert_equal('{"id":1,"name":"Meg"}',
                 simple_blueprinter_class.render(my_obj))
  end

  def test_renaming_keys
    my_obj = OpenStruct.new(id: 1, name: 'Meg')
    rename_blueprinter_class = Class.new(Blueprinter::Base) do
      field :id, name: :identifier
      field :name
    end
    assert_equal('{"identifier":1,"name":"Meg"}',
                 rename_blueprinter_class.render(my_obj))
  end

  def test_fields_using_custom_serializers
    upcase_serializer = Class.new(Blueprinter::Serializer) do
      def serialize(field_name, object, options={})
        object.public_send(field_name).upcase
      end
    end
    my_obj = OpenStruct.new(id: 1, name: 'Meg')

    upcase_blueprinter_class = Class.new(Blueprinter::Base) do
      field :id
      field :name, serializer: upcase_serializer
    end
    assert_equal('{"id":1,"name":"MEG"}',
                 upcase_blueprinter_class.render(my_obj))
  end

  def test_accepts_array_of_fields
    my_obj = OpenStruct.new(id: 1, name: 'Meg', description: 'A person')
    my_klass = Class.new(Blueprinter::Base) do
      identifier :id
      fields :name, :description
    end
    assert_equal('{"id":1,"description":"A person","name":"Meg"}', my_klass.render(my_obj))
  end

  def test_views
    my_obj = OpenStruct.new(id: 1, name: 'Meg', position: 'Manager', description: 'A person', 'company': 'Procore')
    view_klass = Class.new(Blueprinter::Base) do
      identifier :id
      view :normal do
        fields :name, :position
        field :company, name: :employer
      end
      view :extended do
        include_view :normal
        field :description
      end
      view :special do
        include_view :extended
        exclude :position
      end
    end
    assert_equal(
      '{"id":1,"employer":"Procore","name":"Meg","position":"Manager"}',
      view_klass.render(my_obj, view: :normal),
      'The normal view should render the right fields'
    )
    assert_equal(
      '{"id":1}',
      view_klass.render(my_obj),
      'The default view should render the right fields'
    )
    assert_equal(
      '{"id":1,"description":"A person","employer":"Procore","name":"Meg","position":"Manager"}',
      view_klass.render(my_obj, view: :extended),
      'The extended view should render the right fields'
    )
    assert_equal(
      '{"id":1,"description":"A person","employer":"Procore","name":"Meg"}',
      view_klass.render(my_obj, view: :special),
      'The special view should render the right fields'
    )
  end

  def test_local_methods
    my_obj = OpenStruct.new(id: 1, name: 'Meg')
    simple_blueprinter_class = Class.new(Blueprinter::Base) do
      identifier :id
      fields :name
      local_method :age { 30 + 1 }
      local_method :address { '777 Test Dr' }
    end
    assert_equal('{"id":1,"address":"777 Test Dr","age":31,"name":"Meg"}',
                 simple_blueprinter_class.render(my_obj))
  end

  def test_local_method_and_object
    my_obj = OpenStruct.new(id: 1, first_name: 'Meg', last_name: 'Ryan')
    simple_blueprinter_class = Class.new(Blueprinter::Base) do
      identifier :id
      local_method :full_name { |obj| "#{obj.first_name} #{obj.last_name}" }
    end
    assert_equal('{"id":1,"full_name":"Meg Ryan"}',
                 simple_blueprinter_class.render(my_obj))
  end
end
