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
        def around_serialize_object(ctx)
          res = yield ctx
          { data: res }
        end
      end
    end
  end

  it "defines multiple extensions" do
    serializer = Blueprinter::V2::Serializer.new(blueprint)
    expect(blueprint.extensions.size).to eq 2
    expect(serializer.hooks.registered? :around_field_value).to be true
    expect(serializer.hooks.registered? :around_serialize_object).to be true
    expect(serializer.hooks.registered? :around_serialize_collection).to be false
  end

  it "runs the extensions" do
    res = blueprint.render({ name: "Foo" }).to_hash
    expect(res).to eq({ data: { name: "FOO" } })
  end
end
