# frozen_string_literal: true

describe "Blueprinter::V2 Extension DSL" do
  let(:instances) { Blueprinter::V2::InstanceCache.new }
  let(:blueprint) do
    blueprint = Class.new(Blueprinter::V2::Base) do
      def self.blueprint_name = "NameBlueprint"
      field :name
      extension do
        def around_field_value(ctx) = yield(ctx).upcase
      end
      extension do
        def around_blueprint(ctx)
          res = yield ctx
          { data: res }
        end
      end
    end
  end

  it "defines multiple extensions" do
    serializer = Blueprinter::V2::Serializer.new(blueprint, {}, instances, initial_depth: 1)
    expect(blueprint.extensions.size).to eq 2
    expect(serializer.hooks.registered? :around_field_value).to be true
    expect(serializer.hooks.registered? :around_blueprint).to be true
  end

  it "names the extensions" do
    expect(blueprint.extensions.map(&:name)).to eq ["NameBlueprint extension", "NameBlueprint extension"]
  end

  it "runs the extensions" do
    res = blueprint.render({ name: "Foo" }).to_hash
    expect(res).to eq({ data: { name: "FOO" } })
  end
end
