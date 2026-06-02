# frozen_string_literal: true

describe Blueprinter::V2::ViewBuilder do
  let(:builder) do
    Blueprinter::V2::ViewBuilder.new(blueprint)
  end

  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :id
      field :name
    end
  end

  it "aliases the parent as the default view" do
    default = builder[:default]
    expect(default).to eq blueprint
  end

  it "evaluates a view on first access" do
    calls = 0
    blueprint.view :foo do
      field :description
      calls += 1
    end

    view = builder[:foo]
    builder[:foo]
    expect(calls).to eq 1
    expect(view.reflections[:default].fields.keys.sort).to eq %i(id name description).sort
  end

  it "fetches a view" do
    blueprint.view :foo do
      field :description
    end

    view = builder.fetch(:foo)
    expect(view.reflections[:default].fields.keys.sort).to eq %i(id name description).sort
  end

  it "throws an error when fetching an invalid name" do
    expect { builder.fetch(:foo) }.to raise_error KeyError
  end

  it "iterates over each view" do
    d = proc { field :description }
    blueprint.view :foo
    blueprint.view :bar

    keys = builder.each.map { |name, _| name }
    expect(keys.sort).to eq %i(default foo bar).sort
  end

  it "handles cyclic references" do
    widget_blueprint = nil
    category_blueprint = Class.new(Blueprinter::V2::Base) do
      self.blueprint_name = "CategoryBlueprint"
      view :cyclic do
        association :widgets, [widget_blueprint[:cyclic]]
      end
    end
    widget_blueprint = Class.new(Blueprinter::V2::Base) do
      self.blueprint_name = "WidgetBlueprint"
      view :cyclic do
        association :category, category_blueprint[:cyclic]
      end
    end
    expect do
      widget_blueprint[:cyclic].reflections
    end.to_not raise_error
  end

  it "allows blueprints to reference their own views" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      set :exclude_if_nil, true

      view :extended do
        field :description
      end

      field :name
      association :child, -> { blueprint[:extended] }
    end

    result = blueprint.render({
      name: 'Foo',
      description: 'About Foo',
      child: {
        name: 'Bar',
        description: 'About Bar'
      }
    }).to_h

    expect(result).to eq({
      name: 'Foo',
      child: {
        name: 'Bar',
        description: 'About Bar'
      }
    })
  end
end
