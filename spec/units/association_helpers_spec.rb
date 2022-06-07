require 'blueprinter/helpers/association_helpers'
require 'spec_helper'

class DummyClass
  include Blueprinter::AssociationHelpers
end

class SingularAssociation
  def macro
    :has_one
  end

  def name
    :association_ids
  end

  def association_ids
    Hash.new
  end
end

class SingularAssociationNoMatchingName
  def macro
    :has_one
  end

  def name
    :does_not_match
  end

  def association_ids
    Hash.new
  end
end

class CollectionAssociation
  def macro
    :has_many
  end

  def name
    :association_ids
  end

  def association_ids
    Hash.new
  end
end

class CollectionAssociationNoMatchingNames
  def macro
    :has_many
  end

  def name
    :does_not_match
  end

  def association_ids
    Hash.new
  end
end

class SingularAssociationChildArray < Array
  def reflect_on_all_associations
    [SingularAssociation.new]
  end
end

class SingularAssociationChildArrayNoMatchingNames < Array
  def reflect_on_all_associations
    [SingularAssociationNoMatchingName.new]
  end
end

class CollectionAssociationChildArray < Array
  def reflect_on_all_associations
    [CollectionAssociation.new]
  end
end

class CollectionAssociationChildArrayNoMatchingNames < Array
  def reflect_on_all_associations
    [CollectionAssociationNoMatchingNames.new]
  end
end

class SingularAssociationDummyRecord
  def association_ids
    []
  end
end

class CollectionAssociationDummyRecord
  def association_ids
    []
  end
end
RSpec.describe Blueprinter::AssociationHelpers do
  it 'should return hash with singular methods' do
    dc = DummyClass.new
    object_relation = SingularAssociationChildArray.new
    object_relation << SingularAssociationDummyRecord.new
    result = dc.get_field_to_association_hash(object_relation)
    expected_hash = Hash.new
    expected_hash[:association_ids] = :association_ids
    expect(result).to eq(expected_hash)
  end

  it 'should return empty hash' do
    dc = DummyClass.new
    object_relation = SingularAssociationChildArrayNoMatchingNames.new
    object_relation << SingularAssociationDummyRecord.new
    result = dc.get_field_to_association_hash(object_relation)
    expected_hash = Hash.new
    expect(result).to eq(expected_hash)
  end

  it 'should return hash with collection methods' do
    dc = DummyClass.new
    object_relation = CollectionAssociationChildArray.new
    object_relation << CollectionAssociationDummyRecord.new
    result = dc.get_field_to_association_hash(object_relation)
    expected_hash = Hash.new
    expected_hash[:association_ids] = :association_ids
    expect(result).to eq(expected_hash)
  end

  it 'should return empty hash for collection methods' do
    dc = DummyClass.new
    object_relation = CollectionAssociationChildArrayNoMatchingNames.new
    object_relation << CollectionAssociationDummyRecord.new
    result = dc.get_field_to_association_hash(object_relation)
    expected_hash = Hash.new
    expect(result).to eq(expected_hash)
  end
end
