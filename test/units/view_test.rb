require './test/test_helper'

class Blueprinter::View::Test < Minitest::Test

  def test_truth
    assert_kind_of Class, Blueprinter::View
  end

  def setup
    @view = Blueprinter::View.new('Basic View')
  end

  def test_it_can_include_a_view
    view_name = :extended
    @view.include_view(view_name)

    assert_equal [view_name], @view.included_view_names
  end

  def test_it_can_exclude_a_field
    field_to_exclude = :extended

    @view.exclude_field(field_to_exclude)

    assert_equal([field_to_exclude], @view.excluded_field_names)
  end

  def test_it_can_shovel_on_a_field
    field = MockField.new(:new_field)
    @view << field

    assert_equal({ field.name => field }, @view.fields)
  end

  def test_it_cannot_shovel_when_field_exists
    field = MockField.new(:original)
    view  = Blueprinter::View.new('Has an existing field', fields: { field.name => field })

    assert_raises(Blueprinter::BlueprinterError) { view << field }
  end

  class MockField
    attr_reader :name
    def initialize(name)
      @name = name
    end
  end
end
