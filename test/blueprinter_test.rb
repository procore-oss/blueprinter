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
      def serialize(field_name, object, _local_options, _options={})
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

  def test_render_with_options
    user = OpenStruct.new(id: 1, first_name: 'Meg', last_name: 'Ryan')
    vehicle = OpenStruct.new(id: 1, make: 'Super Car')
    simple_blueprinter_class = Class.new(Blueprinter::Base) do
      identifier :id
      field :vehicle_make { |_obj, options| "#{options[:vehicle].make}" }
    end
    assert_equal('{"id":1,"vehicle_make":"Super Car"}',
                 simple_blueprinter_class.render(user, vehicle: vehicle))
  end
end
