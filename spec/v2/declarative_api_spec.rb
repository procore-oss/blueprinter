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

  it "can be used in a Ruby module" do
    mod = Module.new do
      extend Blueprinter::V2::DSL

      set :my_option, true
      field :foo
      partial :my_partial do
        field :description
      end
      view :my_view do
        field :bar
      end
    end

    # test that DSL modules can include other DSL modules
    mod2 = Module.new do
      extend Blueprinter::V2::DSL
      include mod
    end

    # test that DSL modules can be included in non-Blueprinter things
    Class.new { include mod2 }

    blueprint = Class.new(Blueprinter::V2::Base) do
      include mod2

      field :zorp
      view :asdf do
        use :my_partial
      end
    end

    refs = blueprint.reflections
    expect(refs[:default].options).to eq({ my_option: true})
    expect(refs[:default].fields.keys).to eq %i[foo zorp]
    expect(refs[:asdf].fields.keys).to eq %i[foo zorp description]
    expect(refs[:my_view].fields.keys).to eq %i[foo zorp bar]
  end
end
