# frozen_string_literal: true

describe "Blueprinter::V2 Declarative API" do
  it "inherits fields defined after the view" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      view :desc do
        field :description
      end

      field :id
      field :name
    end

    refs = blueprint.reflections
    expect(refs[:desc].fields.keys.sort).to eq %i(id name description).sort
  end

  it "includes partials defined after the view" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name

      view :foo do
        use :desc
      end

      partial :desc do
        field :description
      end
    end

    refs = blueprint.reflections
    expect(refs[:foo].fields.keys.sort).to eq %i(name description).sort
  end

  it "includes partials defined after the use statement" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
      use :desc

      partial :desc do
        field :description
      end
    end

    refs = blueprint.reflections
    expect(refs[:default].fields.keys.sort).to eq %i(name description).sort
  end

  it "inherits when accessing views" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      use :desc
      field :name

      view :foo do
        field :foo

        view :bar do
          field :bar
        end
      end

      partial :desc do
        field :description
      end
    end

    refs = blueprint[:"foo.bar"].reflections
    expect(refs[:default].fields.keys.sort).to eq %i(name foo bar description).sort
  end

  it "excludes fields added after the exclude statement" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :id
      field :name

      view :foo do
        exclude :name, :description2, :description3
        use :desc
        field :description3
      end

      partial :desc do
        field :description
        field :description2
      end
    end

    refs = blueprint.reflections
    expect(refs[:foo].fields.keys.sort).to eq %i(id description).sort
  end
end
