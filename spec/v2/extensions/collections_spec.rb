# frozen_string_literal: true

require 'ostruct'

describe Blueprinter::V2::Extensions::Collections do
  include ExtensionHelpers

  subject { described_class.new }

  it 'should recognize an Array as a collection' do
    expect(subject.collection? []).to be true
  end

  it 'should recognize a Set as a collection' do
    expect(subject.collection? Set.new).to be true
  end

  it 'should recognize an Enumerator as a collection' do
    enum = Enumerator.new { |y| y << 'foo' }
    expect(subject.collection? enum).to be true
  end

  it 'should recognize an integer as an object' do
    expect(subject.collection? 5).to be false
  end

  it 'should recognize a String as an object' do
    expect(subject.collection? 'foo').to be false
  end

  it 'should recognize a Hash as an object' do
    expect(subject.collection?({})).to be false
  end

  it 'should recognize a Struct as an object' do
    x = Struct.new(:foo)
    expect(subject.collection? x.new).to be false
  end

  it 'should recognize an OpenStruct as an object' do
    x = OpenStruct.new
    expect(subject.collection? x).to be false
  end
end
