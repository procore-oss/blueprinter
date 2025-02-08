# frozen_string_literal: true

describe "Blueprinter::V2 Partials" do
  it "allows a partial to be used in any view" do
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

  it "accepts multiple partials" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name

      view :extended do
        use :description, :tags
      end

      partial(:description) { field :description }
      partial(:tags) { field :tags }
    end

    refs = blueprint.reflections
    expect(refs[:extended].fields.keys.sort).to eq %i(name description tags).sort
  end

  it "allows use statements to be nested" do
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

  it "allows a view to be defined in a partial" do
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

  it "throws an error for an invalid partial name" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      view :foo do
        use :description
      end
    end
    expect { blueprint[:foo] }.to raise_error(Blueprinter::Errors::UnknownPartial)
  end

  it 'creates an implicit partial for every view' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      view :foo do
        field :name
      end

      view :bar do
        use :foo
        field :description
      end
    end

    refs = blueprint.reflections
    expect(refs[:bar].fields.keys).to eq %i(name description).sort
  end

  context 'precedence' do
    it 'partials override what the view inherits' do
      blueprint = Class.new(Blueprinter::V2::Base) do
        field :name

        view :foo do
          use :non_empty_name
        end

        partial :non_empty_name do
          field :name, exclude_if_empty: true
        end
      end

      view = blueprint.reflections[:foo]
      expect(view.fields[:name].options).to eq({ exclude_if_empty: true })
    end

    it '`use` overrides the view' do
      blueprint = Class.new(Blueprinter::V2::Base) do
        view :foo do
          use :non_empty_name
          field :name
        end

        partial :non_empty_name do
          field :name, exclude_if_empty: true
        end
      end

      view = blueprint.reflections[:foo]
      expect(view.fields[:name].options).to eq({ exclude_if_empty: true })
    end

    it '`use!` allows the view to override' do
      blueprint = Class.new(Blueprinter::V2::Base) do
        view :foo do
          use! :non_empty_name
          field :name
        end

        partial :non_empty_name do
          field :name, exclude_if_empty: true
        end
      end

      view = blueprint.reflections[:foo]
      expect(view.fields[:name].options).to eq({})
    end
  end
end
