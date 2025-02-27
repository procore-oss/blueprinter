# frozen_string_literal: true

describe "Blueprinter::V2 Extension DSL" do
  let(:blueprint) do
    blueprint = Class.new(Blueprinter::Blueprint) do
      def self.blueprint_name = "NameBlueprint"
      field :name
      extension do
        def field_value(ctx) = ctx.value.upcase
      end
      extension do
        def blueprint_output(ctx) = { data: ctx.value }
      end
    end
  end

  it "should define multiple extensions" do
    expect(blueprint.extensions.size).to eq 2
    expect(blueprint.serializer.hooks.has? :field_value).to be true
    expect(blueprint.serializer.hooks.has? :blueprint_output).to be true
    expect(blueprint.serializer.hooks.has? :object_value).to be false
  end

  it "should name the extensions" do
    expect(blueprint.extensions.map(&:class).map(&:name)).to eq ["NameBlueprint extension", "NameBlueprint extension"]
  end

  it "should run the extensions" do
    res = blueprint.render({ name: "Foo" }).to_hash
    expect(res).to eq({ data: { name: "FOO" } })
  end
end
