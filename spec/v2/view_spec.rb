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
        options[:exclude_if_nil] = true
        extensions << Class.new(Blueprinter::Extension).new
        fields :id
        view(:identifier, empty: true) { field :id }
      end
    end

    let(:blueprint) do
      Class.new(application_blueprint) do
        fields :name, :date

        view :extended do
          field :description
        end
      end
    end

    it "inherits options" do
      expect(blueprint.options).to eq({ exclude_if_nil: true })
      expect(blueprint[:extended].options).to eq({ exclude_if_nil: true })
    end

    it "inherits extensions" do
      expect(blueprint.extensions.size).to eq 1
      expect(blueprint[:extended].extensions.size).to eq 1
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
  end
end
