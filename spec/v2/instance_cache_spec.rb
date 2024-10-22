# frozen_string_literal: true

describe Blueprinter::V2::InstanceCache do
  subject { described_class.new }

  it "should return a new instance" do
    klass = Class.new
    expect(subject[klass]).to be_a klass
  end

  it "should return the cached instance" do
    klass = Class.new
    res1 = subject[klass]
    res2 = subject[klass]
    expect(res2.object_id).to eq res1.object_id
  end

  it "should return x if x is an instance" do
    x = proc { "foo" }
    expect(subject[x]).to eq x
  end
end
