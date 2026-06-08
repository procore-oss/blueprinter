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

  it "an exclusion in a partial still allows things from that partial" do
    blueprint = Class.new(application_blueprint) do
      add Blueprinter::Extensions::FieldOrder.new { |a, b| a.name <=> b.name }
      set :foo, "foo"
      field :name

      use :my_partial

      partial :my_partial do
        add Blueprinter::Extensions::MultiJson.new
        set :bar, "bar"
        format(FalseClass) { "N" }
        field :description
        exclude fields: true, options: true, extensions: true, formatters: true
      end
    end

    ref = blueprint.reflections[:default]
    expect(ref.fields.keys).to eq %i[name description]
    expect(ref.options).to eq({ foo: "foo", bar: "bar" })
    expect(ref.extensions.map(&:class).map(&:name)).to eq %w[Blueprinter::Extensions::FieldOrder Blueprinter::Extensions::MultiJson]
    expect(blueprint.formatters.keys).to eq [FalseClass]
  end

  it "a partial can exclude things from other partials it uses" do
    blueprint = Class.new(application_blueprint) do
      set :foo, "foo"
      add Blueprinter::Extensions::MultiJson.new

      use :my_partial
      fields :id, :name

      partial :my_partial do
        use :other_partial
        exclude fields: true, options: true, extensions: true, formatters: true
      end

      partial :other_partial do
        add Blueprinter::Extensions::FieldOrder.new { |a, b| a.name <=> b.name }
        set :bar, "bar"
        format(FalseClass) { "N" }
        field :description
      end
    end

    ref = blueprint.reflections[:default]
    expect(ref.fields.keys).to eq %i[id name]
    expect(ref.options).to eq({ foo: "foo" })
    expect(ref.extensions.map(&:class).map(&:name)).to eq %w[Blueprinter::Extensions::MultiJson]
    expect(blueprint.formatters.keys).to eq []
  end

  it "specific fields can be excluded by nested partials" do
    blueprint = Class.new(application_blueprint) do
      use :my_partial
      field :name

      partial :my_partial do
        use :nested_partial
        field :description
        exclude :updated_at, :asdf

        partial :nested_partial do
          exclude :created_at
          fields :asdf, :zxcv
        end
      end
    end

    ref = blueprint.reflections[:default]
    expect(ref.fields.keys).to match_array %i[id name description zxcv]
  end
end
