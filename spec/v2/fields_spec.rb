# frozen_string_literal: true

describe "Blueprinter::V2 Fields" do
  context "fields" do
    it "should add fields with options" do
      blueprint = Class.new(Blueprinter::V2) do
        field :name
        field :description, from: :desc, if: -> { true }
        field(:foo) { "foo" }
      end
      expect(blueprint.fields[:name].class.name).to eq "Blueprinter::V2::Field"
      expect(blueprint.fields[:name].name).to eq :name
      expect(blueprint.fields[:name].from).to eq :name
      expect(blueprint.fields[:description].name).to eq :description
      expect(blueprint.fields[:description].from).to eq :desc
      expect(blueprint.fields[:description].if_cond.class.name).to eq "Proc"
      expect(blueprint.fields[:foo].name).to eq :foo
      expect(blueprint.fields[:foo].value_proc.class.name).to eq "Proc"
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
      expect(blueprint.fields[:category].class.name).to eq "Blueprinter::V2::Association"
      expect(blueprint.fields[:category].name).to eq :category
      expect(blueprint.fields[:category].from).to eq :category
      expect(blueprint.fields[:category].blueprint).to eq category_blueprint
      expect(blueprint.fields[:widgets].name).to eq :widgets
      expect(blueprint.fields[:widgets].from).to eq :foo
      expect(blueprint.fields[:widgets].blueprint).to eq widget_blueprint
      expect(blueprint.fields[:widgets].if_cond.class.name).to eq "Proc"
      expect(blueprint.fields[:foo].name).to eq :foo
      expect(blueprint.fields[:foo].blueprint).to eq widget_blueprint
      expect(blueprint.fields[:foo].value_proc.class.name).to eq "Proc"
    end
  end

  it "it should inherit from parent classes" do
    application_blueprint = Class.new(Blueprinter::V2) do
      field :id
    end
    blueprint = Class.new(application_blueprint) do
      field :name
    end
    expect(blueprint.fields.keys).to eq %i(id name)
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

    expect(blueprint.fields.keys).to eq %i(name)
    expect(blueprint[:default].fields.keys).to eq %i(name)
    expect(blueprint[:extended].fields.keys).to eq %i(name description)
    expect(blueprint[:extended][:plus].fields.keys).to eq %i(name description foo)
  end

  it "should exclude specified views and associations" do
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

    expect(blueprint.fields.keys).to eq %i(id name category widgets)
    expect(blueprint[:foo].fields.keys).to eq %i(id widgets description)
  end
end
