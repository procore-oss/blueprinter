# frozen_string_literal: true

describe "Blueprinter::V2::ViewBuilder" do
  let(:builder) do
    Blueprinter::V2::ViewBuilder.new(blueprint)
  end

  let(:blueprint) do
    Class.new(Blueprinter::V2) do
      field :id
      field :name
    end
  end

  it "should alias the parent as the default view" do
    default = builder[:default]
    expect(default).to eq blueprint
  end

  it "should store, but not evaluate, a view" do
    calls = 0
    builder[:foo] =
      proc do
        field :description
        calls += 1
      end

    expect(calls).to eq 0
  end

  it "should evaluate a view on first access" do
    calls = 0
    builder[:foo] =
      proc do
        field :description
        calls += 1
      end

    view = builder[:foo]
    builder[:foo]
    expect(calls).to eq 1
    expect(view.reflections[:default].fields.keys.sort).to eq %i(id name description).sort
  end

  it "should fetch a view" do
    builder[:foo] = proc { field :description }

    view = builder.fetch(:foo)
    expect(view.reflections[:default].fields.keys.sort).to eq %i(id name description).sort
  end

  it "should throw an error when fetching an invalid name" do
    expect { builder.fetch(:foo) }.to raise_error KeyError
  end

  it "should iterate over each view" do
    builder[:foo] = proc { field :description }
    builder[:bar] = proc { field :description }

    keys = builder.each.map { |name, _| name }
    expect(keys.sort).to eq %i(default foo bar).sort
  end
end
