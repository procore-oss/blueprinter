# frozen_string_literal: true

describe Blueprinter::V2::ViewBuilder do
  let(:builder) do
    Blueprinter::V2::ViewBuilder.new(blueprint)
  end

  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
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
    d = proc do
      field :description
      calls += 1
    end
    builder[:foo] = definition(d)

    expect(calls).to eq 0
  end

  it "should evaluate a view on first access" do
    calls = 0
    d = proc do
      field :description
      calls += 1
    end
    builder[:foo] = definition(d)

    view = builder[:foo]
    builder[:foo]
    expect(calls).to eq 1
    expect(view.reflections[:default].fields.keys.sort).to eq %i(id name description).sort
  end

  it "should fetch a view" do
    d = proc { field :description }
    builder[:foo] = definition(d)

    view = builder.fetch(:foo)
    expect(view.reflections[:default].fields.keys.sort).to eq %i(id name description).sort
  end

  it "should throw an error when fetching an invalid name" do
    expect { builder.fetch(:foo) }.to raise_error KeyError
  end

  it "should iterate over each view" do
    d = proc { field :description }
    builder[:foo] = definition(d)
    builder[:bar] = definition(d)

    keys = builder.each.map { |name, _| name }
    expect(keys.sort).to eq %i(default foo bar).sort
  end

  it "doesn't throw an error if you try to redefine an existing view" do
    d = proc { field :description }
    builder[:foo] = definition(d)
    expect do
      d = proc { field :description }
      builder[:foo] = definition(d)
    end.to_not raise_error
  end

  it "throws an error if you try to define the default view" do
    d = proc { field :description }
    expect {
      builder[:default] = definition(d)
    }.to raise_error Blueprinter::Errors::InvalidBlueprint
  end

  context "reset" do
    it "clears all views but default" do
      d = proc { field :description }
      builder[:foo] = definition(d)
      builder[:bar] = definition(d)
      builder.reset

      expect(builder[:foo]).to be_nil
      expect(builder[:bar]).to be_nil
      expect(builder[:default]).to eq blueprint
    end
  end

  context "dup_for" do
    let(:blueprint2) { Class.new(blueprint) { field :description } }

    it "duplicates views for another blueprint" do
      d = proc { field :description }
      builder[:foo] = definition(d)
      builder[:bar] = definition(d)
      builder2 = builder.dup_for(blueprint2)

      expect(builder[:default]).to eq blueprint
      expect(builder2[:default]).to eq blueprint2
      expect(builder2[:foo]).to_not be_nil
      expect(builder2[:bar]).to_not be_nil
    end
  end

  def definition(definition)
    described_class::Def.new(definition:, fields: true, options: true, extensions: true)
  end
end
