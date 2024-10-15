# frozen_string_literal: true

describe "Blueprinter::V2 Partials" do
  it "should allow a partial to be used in any view" do
    blueprint = Class.new(Blueprinter::V2::Base) do
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

    refs = blueprint.reflections
    expect(refs[:default].fields.keys.sort).to eq %i(name).sort
    expect(refs[:foo].fields.keys.sort).to eq %i(name description).sort
    expect(refs[:bar].fields.keys.sort).to eq %i(name description).sort
  end

  it "should allow use statements to be nested" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
      use :foo

      partial :foo do
        field :foo
        use :bar
      end

      partial :bar do
        field :bar
        use :zorp
      end

      partial :zorp do
        field :zorp
      end
    end

    refs = blueprint.reflections
    expect(refs[:default].fields.keys.sort).to eq %i(name foo bar zorp).sort
  end

  it "should allow a view to be defined in a partial" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name

      view :foo do
        use :desc
      end

      view :bar do
        use :desc
      end

      partial :desc do
        field :description

        view :extended do
          field :long_description
        end
      end
    end

    refs = blueprint.reflections
    expect(refs[:foo].fields.keys.sort).to eq %i(name description).sort
    expect(refs[:bar].fields.keys.sort).to eq %i(name description).sort
    expect(refs[:"foo.extended"].fields.keys.sort).to eq %i(name description long_description).sort
    expect(refs[:"bar.extended"].fields.keys.sort).to eq %i(name description long_description).sort
  end

  it "should throw an error for an invalid partial name" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      view :foo do
        use :description
      end
    end
    expect { blueprint[:foo] }.to raise_error(Blueprinter::Errors::UnknownPartial)
  end
end
