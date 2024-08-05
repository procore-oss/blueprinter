# frozen_string_literal: true

describe "Blueprinter::V2 Reflection" do
  it "should find all view names" do
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
end
