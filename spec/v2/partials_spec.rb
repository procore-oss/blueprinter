# frozen_string_literal: true

describe "Blueprinter::V2 Partials" do
  it "should allow a partial to be used in any view" do
    blueprint = Class.new(Blueprinter::V2) do
      field :name

      partial :description do
        field :description
      end

      view :foo do
        use :description
      end

      view :bar do
        use :description
      end
    end

    expect(blueprint.reflections[:default].fields.keys).to eq %i(name)
    expect(blueprint.reflections[:foo].fields.keys.sort).to eq %i(
      name
      description
    ).sort
    expect(blueprint.reflections[:bar].fields.keys.sort).to eq %i(
      name
      description
    ).sort
  end

  it "should throw an error for an invalid partial name" do
    expect do
      Class.new(Blueprinter::V2) do
        view :foo do
          use :description
        end
      end
    end.to raise_error(Blueprinter::Errors::UnknownPartial)
  end
end
