# frozen_string_literal: true

describe "Blueprinter::V2 Views" do
  let(:application_blueprint) do
    Class.new(Blueprinter::V2::Base) do
      fields :id, :timestamp
    end
  end

  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      fields :id, :name

      view :extended do
        field :description

        view :plus do
          field :foo
        end

        view :plus2 do
          field :price
        end
      end
    end
  end

  it "invalid views can be referenced before eval" do
    expect { blueprint[:"asdf"] }.to_not raise_error
    expect { blueprint[:"asdf.zxcv"] }.to_not raise_error
    expect { blueprint[:"extended.plus3"] }.to_not raise_error
  end

  it "throws if a view doesn't exist AFTER it's been evaled" do
    blueprint.reflections
    expect { blueprint[:"asdf"] }.to raise_error(Blueprinter::Errors::UnknownView)
    expect { blueprint[:"asdf.zxcv"] }.to raise_error(Blueprinter::Errors::UnknownView)

    blueprint[:extended].reflections
    expect { blueprint[:"extended.plus3"] }.to raise_error(Blueprinter::Errors::UnknownView)
  end

  it "are inherited by other blueprints" do
    blueprint2 = Class.new(blueprint) do
      view :foo do
        field :foo
      end
    end
    expect(blueprint2.reflections.keys.sort).to eq(%i[default extended extended.plus extended.plus2 foo])
  end

  it "are not inherited by other views" do
    expect(blueprint[:"extended.plus2"].reflections.keys.sort).to eq(%i[default])
  end

  context "fields, options, and extensions" do
    let(:application_blueprint) do
      Class.new(Blueprinter::V2::Base) do
        self.blueprint_name = 'ApplicationBlueprint'
        set :exclude_if_nil, true
        add Class.new(Blueprinter::Extension).new
        fields :id
        view :identifier do
          exclude fields: true
          field :id
        end
      end
    end

    let(:blueprint) do
      Class.new(application_blueprint) do
        self.blueprint_name = 'MyBlueprint'
        fields :name, :date

        view :extended do
          field :description
        end
      end
    end

    it "inherits options" do
      ref = blueprint.reflections
      expect(ref[:default].options).to eq({ exclude_if_nil: true })
      expect(ref[:extended].options).to eq({ exclude_if_nil: true })
    end

    it "inherits extensions" do
      ref = blueprint.reflections
      expect(ref[:default].extensions.size).to eq 1
      expect(ref[:extended].extensions.size).to eq 1
    end

    it "inherits fields by default" do
      ref = blueprint.reflections
      expect(ref[:default].fields.keys).to eq %i[id name date]
      expect(ref[:extended].fields.keys).to eq %i[id name date description]
    end

    it "can opt out of inheriting fields" do
      expect(application_blueprint.reflections[:identifier].fields.keys).to eq %i[id]
    end

    it "inherits views which opted out of inheriting fields" do
      expect(blueprint.reflections[:identifier].fields.keys).to eq %i[id]
    end

    it "can be extended" do
      bp1 = Class.new(Blueprinter::V2::Base) do
        view(:foo) { fields :id, :name }
      end
      bp2 = Class.new(bp1) do
        view(:foo) { field :description }
      end
      expect(bp2.reflections[:foo].fields.keys.sort).to eq %i(description id name)
    end

    it "throws an error if you try to define the default view" do
      expect do
        Class.new(Blueprinter::V2::Base) do
          view :default do
            field :name
          end
        end
      end.to raise_error Blueprinter::Errors::InvalidBlueprint
    end

    it "handles cyclic references" do
      widget_blueprint = nil
      category_blueprint = Class.new(Blueprinter::V2::Base) do
        self.blueprint_name = "CategoryBlueprint"
        view :cyclic do
          association :widgets, [widget_blueprint[:cyclic]]
        end
      end
      widget_blueprint = Class.new(Blueprinter::V2::Base) do
        self.blueprint_name = "WidgetBlueprint"
        view :cyclic do
          association :category, category_blueprint[:cyclic]
        end
      end
      expect do
        widget_blueprint[:cyclic].reflections
      end.to_not raise_error
    end

    it "allows blueprints to reference their own views" do
      blueprint = Class.new(Blueprinter::V2::Base) do
        set :exclude_if_nil, true

        field :name
        association :child, self[:extended]

        view :extended do
          field :description
        end
      end

      result = blueprint.render({
        name: 'Foo',
        description: 'About Foo',
        child: {
          name: 'Bar',
          description: 'About Bar'
        }
      }).to_h

      expect(result).to eq({
        name: 'Foo',
        child: {
          name: 'Bar',
          description: 'About Bar'
        }
      })
    end
  end
end
