# frozen_string_literal: true

describe "Blueprinter::V2 Fields" do
  context "fields" do
    it "should add fields with options" do
      blueprint = Class.new(Blueprinter::V2) do
        field :name
        field :description, from: :desc, if: -> { true }
        field(:foo) { "foo" }
      end

      ref = blueprint.reflections[:default]
      expect(ref.fields[:name].class.name).to eq "Blueprinter::V2::Field"
      expect(ref.fields[:name].name).to eq :name
      expect(ref.fields[:name].from).to eq :name
      expect(ref.fields[:description].name).to eq :description
      expect(ref.fields[:description].from).to eq :desc
      expect(ref.fields[:description].if_cond.class.name).to eq "Proc"
      expect(ref.fields[:foo].name).to eq :foo
      expect(ref.fields[:foo].value_proc.class.name).to eq "Proc"
    end
  end

  context "associations" do
    it "should add associations with options" do
      category_blueprint = Class.new(Blueprinter::V2)
      widget_blueprint = Class.new(Blueprinter::V2)
      blueprint = Class.new(Blueprinter::V2) do
        association :category, category_blueprint
        association :widgets, widget_blueprint, from: :foo, if: -> { true }
        association(:foo, widget_blueprint) { {foo: "bar"} }
      end

      ref = blueprint.reflections[:default]
      expect(ref.associations[:category].class.name).to eq "Blueprinter::V2::Association"
      expect(ref.associations[:category].name).to eq :category
      expect(ref.associations[:category].from).to eq :category
      expect(ref.associations[:category].blueprint).to eq category_blueprint
      expect(ref.associations[:widgets].name).to eq :widgets
      expect(ref.associations[:widgets].from).to eq :foo
      expect(ref.associations[:widgets].blueprint).to eq widget_blueprint
      expect(ref.associations[:widgets].if_cond.class.name).to eq "Proc"
      expect(ref.associations[:foo].name).to eq :foo
      expect(ref.associations[:foo].blueprint).to eq widget_blueprint
      expect(ref.associations[:foo].value_proc.class.name).to eq "Proc"
    end
  end

  it "it should inherit from parent classes" do
    application_blueprint = Class.new(Blueprinter::V2) do
      field :id
    end
    blueprint = Class.new(application_blueprint) do
      field :name
    end

    ref = blueprint.reflections[:default]
    expect(ref.fields.keys).to eq %i(id name)
  end

  it "it should inherit from parent views" do
    blueprint = Class.new(Blueprinter::V2) do
      field :name

      view :extended do
        field :description

        view :plus do
          field :foo
        end
      end
    end

    refs = blueprint.reflections
    expect(refs[:default].fields.keys.sort).to eq %i(name).sort
    expect(refs[:extended].fields.keys.sort).to eq %i(name description).sort
    expect(refs[:"extended.plus"].fields.keys.sort).to eq %i(name description foo).sort
  end

  it "should exclude specified fields and associations from the parent class" do
    application_blueprint = Class.new(Blueprinter::V2) do
      field :id
      field :foo
    end
    blueprint = Class.new(application_blueprint) do
      exclude :foo
      field :name
    end

    refs = blueprint.reflections
    expect(refs[:default].fields.keys.sort).to eq %i(id name).sort
  end

  it "should exclude specified fields and associations from the parent view" do
    category_blueprint = Class.new(Blueprinter::V2)
    widget_blueprint = Class.new(Blueprinter::V2)
    blueprint = Class.new(Blueprinter::V2) do
      field :id
      field :name
      association :category, category_blueprint
      association :widgets, widget_blueprint

      view :foo do
        exclude :name, :category
        field :description
      end
    end

    refs = blueprint.reflections
    expect(refs[:default].fields.keys.sort).to eq %i(id name).sort
    expect(refs[:default].associations.keys.sort).to eq %i(category widgets).sort
    expect(refs[:foo].fields.keys.sort).to eq %i(id description).sort
    expect(refs[:foo].associations.keys.sort).to eq %i(widgets).sort
  end

  it "should exclude specified fields and associations from partials" do
    blueprint = Class.new(Blueprinter::V2) do
      partial :desc do
        field :short_desc
        field :long_desc
      end

      field :name

      view :foo do
        exclude :short_desc
        use :desc
      end
    end

    refs = blueprint.reflections
    expect(refs[:foo].fields.keys).to eq %i(name long_desc)
  end
end
