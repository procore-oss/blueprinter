# frozen_string_literal: true

describe "Blueprinter::V2 Reflection" do
  it "should find all view keys" do
    blueprint = Class.new(Blueprinter::V2) do
      view :foo
      view :bar do
        view :foo do
          view :borp
        end
      end
    end

    view_names = blueprint.reflections.keys
    expect(view_names.sort).to eq %i(
      default
      foo
      bar
      bar.foo
      bar.foo.borp
    ).sort
  end

  it "should find all view names" do
    blueprint = Class.new(Blueprinter::V2) do
      view :foo
      view :bar do
        view :foo do
          view :borp
        end
      end
    end

    views = blueprint.reflections.values
    expect(views.map(&:name).sort).to eq %i(
      default
      foo
      bar
      bar.foo
      bar.foo.borp
    ).sort
  end

  it "should find fields and associations" do
    category_blueprint = Class.new(Blueprinter::V2)
    widget_blueprint = Class.new(Blueprinter::V2)
    blueprint = Class.new(Blueprinter::V2) do
      field :name
      association :category, category_blueprint

      view :extended do
        field :description
        association :widgets, widget_blueprint
      end
    end

    expect blueprint.reflections[:default].fields.keys to eq %i(name)
    expect blueprint.reflections[:default].associations.keys to eq %i(name)

    expect blueprint.reflections[:extended].fields.keys to eq %i(name description)
    expect blueprint.reflections[:extended].associations.keys to eq %i(name widgets)
  end
end
