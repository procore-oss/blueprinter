# frozen_string_literal: true

describe "Blueprinter::V2 Views" do
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
end
