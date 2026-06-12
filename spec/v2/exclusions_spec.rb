# frozen_string_literal: true

describe "Blueprinter::V2 Exclusions" do
  let(:application_blueprint) do
    Class.new(Blueprinter::V2::Base) do
      add Blueprinter::Extensions::ViewOption.new
      set :my_opt, true
      format(TrueClass) { "Y" }
      fields :id, :created_at, :updated_at
    end
  end

  it "excludes from parent class" do
    blueprint = Class.new(application_blueprint) do
      add Blueprinter::Extensions::FieldOrder.new { |a, b| a.name <=> b.name }
      set :foo, "foo"
      field :name
      exclude fields: true, options: true, extensions: true, formatters: true
    end

    ref = blueprint.reflections[:default]
    expect(ref.fields.keys).to eq %i[name]
    expect(ref.options).to eq({ foo: "foo" })
    expect(ref.extensions.map(&:class).map(&:name)).to eq %w[Blueprinter::Extensions::FieldOrder]
    expect(blueprint.formatters).to eq({})
  end

  it "allows a locally defined field" do
    blueprint = Class.new(application_blueprint) do
      add Blueprinter::Extensions::FieldOrder.new { |a, b| a.name <=> b.name }
      set :foo, "foo"
      fields :name, :created_at
      exclude :created_at, :updated_at
    end

    ref = blueprint.reflections[:default]
    expect(ref.fields.keys).to match_array %i[id name created_at]
  end

  it "excludes from view parent" do
    blueprint = Class.new(application_blueprint) do
      add Blueprinter::Extensions::FieldOrder.new { |a, b| a.name <=> b.name }
      set :foo, "foo"
      field :name

      view :extended do
        add Blueprinter::Extensions::MultiJson.new
        set :bar, "bar"
        field :description
        exclude fields: true, options: true, extensions: true, formatters: true
      end
    end

    ref = blueprint.reflections[:extended]
    expect(ref.fields.keys).to eq %i[description]
    expect(ref.options).to eq({ bar: "bar" })
    expect(ref.extensions.map(&:class).map(&:name)).to eq %w[Blueprinter::Extensions::MultiJson]
    expect(blueprint[:extended].formatters).to eq({})
  end

  it "excludes from parent view" do
    blueprint = Class.new(application_blueprint) do
      view :extended do
        add Blueprinter::Extensions::FieldOrder.new { |a, b| a.name <=> b.name }
        set :foo, "foo"
        field :name

        view :plus do
          add Blueprinter::Extensions::MultiJson.new
          set :bar, "bar"
          field :description
          exclude fields: true, options: true, extensions: true, formatters: true
        end
      end
    end

    ref = blueprint.reflections[:"extended.plus"]
    expect(ref.fields.keys).to eq %i[description]
    expect(ref.options).to eq({ bar: "bar" })
    expect(ref.extensions.map(&:class).map(&:name)).to eq %w[Blueprinter::Extensions::MultiJson]
    expect(blueprint[:"extended.plus"].formatters).to eq({})
  end

  it "exclusions can be added by a partial" do
    blueprint = Class.new(application_blueprint) do
      add Blueprinter::Extensions::FieldOrder.new { |a, b| a.name <=> b.name }
      set :foo, "foo"
      field :name

      use :my_partial

      partial :my_partial do
        exclude fields: true, options: true, extensions: true, formatters: true
      end
    end

    ref = blueprint.reflections[:default]
    expect(ref.fields.keys).to eq %i[name]
    expect(ref.options).to eq({ foo: "foo" })
    expect(ref.extensions.map(&:class).map(&:name)).to eq %w[Blueprinter::Extensions::FieldOrder]
    expect(blueprint.formatters).to eq({})
  end
end
