# frozen_string_literal: true

require 'blueprinter/view_wrapper'

describe Blueprinter::ViewWrapper do
  let(:blueprint) do
    Class.new(Blueprinter::Base) do
      field :name
      view :extended do
        field :description
      end
    end
  end

  let(:input) { { name: 'foo', description: 'bar' } }
  let(:output) { { description: 'bar', name: 'foo' } }
  let(:wrapper) { described_class.new(blueprint, :extended) }

  context 'render' do
    it 'should render a view' do
      expect(wrapper.render(input)).to eq output.to_json
    end

    it 'should render a view with options' do
      expect(wrapper.render(input, root: :data)).to eq({ data: output }.to_json)
    end
  end

  context 'render_as_hash' do
    it 'should render a view' do
      expect(wrapper.render_as_hash(input)).to eq output
    end

    it 'should render a view with options' do
      expect(wrapper.render_as_hash(input, root: :data)).to eq({ data: output })
    end
  end

  it 'should return the reflections' do
    expect(wrapper.reflections[:extended].fields.keys).to match_array [:name, :description]
  end

  it 'should fetch the default view from a blueprint' do
    default = blueprint[:default]
    expect(default.blueprint).to eq blueprint
    expect(default.view_name).to eq :default
  end

  it 'should fetch a given view from a blueprint' do
    extended = blueprint[:extended]
    expect(extended.blueprint).to eq blueprint
    expect(extended.view_name).to eq :extended
  end

  it 'should raise an error if the view does not exist' do
    expect { blueprint[:foo] }.to raise_error(Blueprinter::Errors::UnknownView)
  end
end
