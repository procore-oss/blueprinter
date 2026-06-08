# frozen_string_literal: true

describe "Blueprinter::V2 Options" do
  it "set overrides options" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      set :foo, "foo"

      view :extended do
        set :foo, "bar"
      end
    end

    refs = blueprint.reflections
    expect(refs[:default].options).to eq({ foo: "foo" })
    expect(refs[:extended].options).to eq({ foo: "bar" })
  end

  it "set can take a block to access the current option value" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      set :foo, "foo"

      view :extended do
        set :foo do |val|
          "#{val}bar"
        end
      end
    end

    refs = blueprint.reflections
    expect(refs[:default].options[:foo]).to eq "foo"
    expect(refs[:extended].options[:foo]).to eq "foobar"
  end

  it "unset unsets options" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      set :foo, "foo"
      set :bar, "bar"

      view :extended do
        set :zorp, "zorp"
        unset :bar, :zorp
      end
    end

    refs = blueprint.reflections
    expect(refs[:default].options).to eq({ foo: "foo", bar: "bar" })
    expect(refs[:extended].options).to eq({ foo: "foo" })
  end

  it "excludes all inherited options" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      set :foo, "foo"
      set :bar, "bar"

      view :extended do
        exclude options: true
        set :zorp, "zorp"
      end
    end

    refs = blueprint.reflections
    expect(refs[:default].options).to eq({ foo: "foo", bar: "bar" })
    expect(refs[:extended].options).to eq({ zorp: "zorp" })
  end
end
