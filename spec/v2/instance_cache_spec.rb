# frozen_string_literal: true

describe Blueprinter::V2::InstanceCache do
  subject { described_class.new }
  let(:klass) { Class.new }
  let(:klass2) { Class.new }

  it "returns a new instance" do
    expect(subject[klass]).to be_a klass
  end

  it "returns the cached instance from a class" do
    res1 = subject[klass]
    res2 = subject[klass]
    res3 = subject[klass2]
    expect(res2.object_id).to eq res1.object_id
    expect(res3.object_id).to_not eq res1.object_id
  end

  it "returns the cached instance from a class with args" do
    klass = Class.new do
      attr_reader :arg1, :arg2

      def initialize(arg1, arg2)
        @arg1 = arg1
        @arg2 = arg2
      end
    end

    res1 = subject[klass, ["foo", "bar"]]
    res2 = subject[klass, ["foo", "bar"]]
    res3 = subject[klass, ["foob", "boop"]]

    expect(res2.object_id).to eq res1.object_id
    expect(res2.arg1).to eq "foo"
    expect(res2.arg2).to eq "bar"

    expect(res3.object_id).to_not eq res2.object_id
    expect(res3.arg1).to eq "foob"
    expect(res3.arg2).to eq "boop"
  end

  it "returns the cached instance from a Proc" do
    p1 = proc { klass.new }
    p2 = proc { klass.new }

    res1 = subject[p1]
    res2 = subject[p1]
    res3 = subject[p2]
    expect(res2.object_id).to eq res1.object_id
    expect(res3.object_id).to_not eq res1.object_id
  end

  it "returns x if x is an instance" do
    x = klass.new
    y = klass.new
    expect(subject[x]).to eq x
    expect(subject[y]).to eq y
  end
end
