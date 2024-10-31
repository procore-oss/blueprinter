# frozen_string_literal: true

describe "Blueprinter::V2 Fields" do
  context "fields" do
    it "should add fields with options" do
      blueprint = Class.new(Blueprinter::V2::Base) do
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
      expect(ref.fields[:description].options[:if].class.name).to eq "Proc"
      expect(ref.fields[:foo].name).to eq :foo
      expect(ref.fields[:foo].value_proc.class.name).to eq "Proc"
    end

    it 'should add multiple fields' do
      blueprint = Class.new(Blueprinter::V2::Base) do
        fields :name, :description, :status
      end

      ref = blueprint.reflections[:default]
      expect(ref.fields[:name].class.name).to eq "Blueprinter::V2::Field"
      expect(ref.fields[:name].name).to eq :name
      expect(ref.fields[:name].options).to eq({})

      expect(ref.fields[:description].class.name).to eq "Blueprinter::V2::Field"
      expect(ref.fields[:description].name).to eq :description
      expect(ref.fields[:description].options).to eq({})

      expect(ref.fields[:status].class.name).to eq "Blueprinter::V2::Field"
      expect(ref.fields[:status].name).to eq :status
      expect(ref.fields[:status].options).to eq({})
    end
  end

  context "associations" do
    it "should add associations with options" do
      category_blueprint = Class.new(Blueprinter::V2::Base)
      widget_blueprint = Class.new(Blueprinter::V2::Base)
      blueprint = Class.new(Blueprinter::V2::Base) do
        object :category, category_blueprint
        collection :widgets, widget_blueprint, from: :foo, if: -> { true }
        object(:foo, widget_blueprint) { {foo: "bar"} }
      end

      ref = blueprint.reflections[:default]
      expect(ref.objects[:category].class.name).to eq "Blueprinter::V2::ObjectField"
      expect(ref.objects[:category].name).to eq :category
      expect(ref.objects[:category].from).to eq :category
      expect(ref.objects[:category].blueprint).to eq category_blueprint
      expect(ref.collections[:widgets].name).to eq :widgets
      expect(ref.collections[:widgets].from).to eq :foo
      expect(ref.collections[:widgets].blueprint).to eq widget_blueprint
      expect(ref.collections[:widgets].options[:if].class.name).to eq "Proc"
      expect(ref.objects[:foo].name).to eq :foo
      expect(ref.objects[:foo].blueprint).to eq widget_blueprint
      expect(ref.objects[:foo].value_proc.class.name).to eq "Proc"
    end
  end

  it "it should inherit from parent classes" do
    application_blueprint = Class.new(Blueprinter::V2::Base) do
      field :id
    end
    blueprint = Class.new(application_blueprint) do
      field :name
    end

    ref = blueprint.reflections[:default]
    expect(ref.fields.keys).to eq %i(id name)
  end

  it "it should inherit from parent views" do
    blueprint = Class.new(Blueprinter::V2::Base) do
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
    application_blueprint = Class.new(Blueprinter::V2::Base) do
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
    category_blueprint = Class.new(Blueprinter::V2::Base)
    widget_blueprint = Class.new(Blueprinter::V2::Base)
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :id
      field :name
      object :category, category_blueprint
      collection :widgets, widget_blueprint

      view :foo do
        exclude :name, :category
        field :description
      end
    end

    refs = blueprint.reflections
    expect(refs[:default].fields.keys.sort).to eq %i(id name).sort
    expect(refs[:default].objects.keys.sort).to eq %i(category).sort
    expect(refs[:default].collections.keys.sort).to eq %i(widgets).sort
    expect(refs[:foo].fields.keys.sort).to eq %i(id description).sort
    expect(refs[:foo].objects.keys.sort).to eq %i().sort
    expect(refs[:foo].collections.keys.sort).to eq %i(widgets).sort
  end

  it "should exclude specified fields and associations from partials" do
    blueprint = Class.new(Blueprinter::V2::Base) do
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
