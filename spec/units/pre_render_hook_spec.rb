# frozen_string_literal: true

require 'ostruct'

describe 'V1 pre_render hook' do
  let(:all_extensions) {
    [
      foo_extension.new,
      bar_extension.new,
      zar_extension.new,
    ]
  }

  let(:foo_extension) {
    Class.new(Blueprinter::Extension) do
      def pre_render(object, _blueprint, _view, _options)
        obj = object.dup
        obj.foo = "Foo"
        obj
      end
    end
  }

  let(:bar_extension) {
    Class.new(Blueprinter::Extension) do
      def pre_render(object, _blueprint, _view, _options)
        obj = object.dup
        obj.bar = "Bar"
        obj
      end
    end
  }

  let(:zar_extension) {
    Class.new(Blueprinter::Extension) do
      def self.something_else(object, _blueprint, _view, _options)
        object
      end
    end
  }

  before :each do
    Blueprinter.configure do |config|
      config.extensions = all_extensions
    end
  end

  after :each do
    Blueprinter.configure do |config|
      config.extensions = []
    end
  end

  let(:test_blueprint) {
    Class.new(Blueprinter::Base) do
      field :id
      field :name
      field :foo

      view :with_bar do
        field :bar
      end
    end
  }

  it 'should run with Blueprinter.render using default view' do
    obj = OpenStruct.new(id: 42, name: 'Jack')
    res = JSON.parse(test_blueprint.render(obj))
    expect(res['id']).to be 42
    expect(res['name']).to eq 'Jack'
    expect(res['foo']).to eq 'Foo'
    expect(res['bar']).to be_nil
  end

  it 'should run with Blueprinter.render using with_bar view' do
    obj = OpenStruct.new(id: 42, name: 'Jack')
    res = JSON.parse(test_blueprint.render(obj, view: :with_bar))
    expect(res['id']).to be 42
    expect(res['name']).to eq 'Jack'
    expect(res['foo']).to eq 'Foo'
    expect(res['bar']).to eq 'Bar'
  end

  it 'should run with Blueprinter.render_as_hash' do
    obj = OpenStruct.new(id: 42, name: 'Jack')
    res = test_blueprint.render_as_hash(obj, view: :with_bar)
    expect(res[:id]).to be 42
    expect(res[:name]).to eq 'Jack'
    expect(res[:foo]).to eq 'Foo'
    expect(res[:bar]).to eq 'Bar'
  end
end
