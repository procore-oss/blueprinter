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
    ref = blueprint.reflections[:default]
    serializer = Blueprinter::V2::Serializer.new(blueprint)
    expect(ref.extensions.size).to eq 2
    expect(serializer.hooks.registered? :around_field_value).to be true
    expect(serializer.hooks.registered? :around_serialize_object).to be true
    expect(serializer.hooks.registered? :around_serialize_collection).to be false
  end

  it "runs the extensions" do
    res = blueprint.render({ name: "Foo" }).to_hash
    expect(res).to eq({ data: { name: "FOO" } })
  end

  it "add appends extensions" do
    ext1 = Class.new(Blueprinter::Extension)
    ext2 = Class.new(Blueprinter::Extension)
    ext3 = Class.new(Blueprinter::Extension)

    blueprint = Class.new(Blueprinter::V2::Base) do
      add ext1.new

      view :extended do
        add ext2.new, ext3.new
      end
    end

    ref = blueprint.reflections
    expect(ref[:default].extensions.map(&:class)).to eq [ext1]
    expect(ref[:extended].extensions.map(&:class)).to eq [ext1, ext2, ext3]
  end

  it "add prepends extensions" do
    ext1 = Class.new(Blueprinter::Extension)
    ext2 = Class.new(Blueprinter::Extension)
    ext3 = Class.new(Blueprinter::Extension)

    blueprint = Class.new(Blueprinter::V2::Base) do
      add ext1.new

      view :extended do
        add ext2.new, ext3.new, prepend: true
      end
    end

    ref = blueprint.reflections
    expect(ref[:default].extensions.map(&:class)).to eq [ext1]
    expect(ref[:extended].extensions.map(&:class)).to eq [ext2, ext3, ext1]
  end

  it "add throws an exception if someone accidentally passes a block" do
    ext1 = Class.new(Blueprinter::Extension)
    expect do
      Class.new(Blueprinter::V2::Base) do
        add ext1.new do
        end
      end
    end.to raise_error(Blueprinter::BlueprinterError, /add does not accept a block/)
  end

  it "remove removes extensions by class" do
    ext1 = Class.new(Blueprinter::Extension)
    ext2 = Class.new(Blueprinter::Extension)
    ext3 = Class.new(Blueprinter::Extension)

    blueprint = Class.new(Blueprinter::V2::Base) do
      add ext1.new, ext2.new, ext3.new

      view :extended do
        remove ext2, ext3
      end
    end

    ref = blueprint.reflections
    expect(ref[:default].extensions.map(&:class)).to eq [ext1, ext2, ext3]
    expect(ref[:extended].extensions.map(&:class)).to eq [ext1]
  end

  it "remove removes extensions with a block" do
    ext1 = Class.new(Blueprinter::Extension)
    ext2 = Class.new(Blueprinter::Extension)
    ext3 = Class.new(Blueprinter::Extension)

    blueprint = Class.new(Blueprinter::V2::Base) do
      add ext1.new, ext2.new, ext3.new

      view :extended do
        remove { |ext| ext.is_a? ext3 }
      end
    end

    ref = blueprint.reflections
    expect(ref[:default].extensions.map(&:class)).to eq [ext1, ext2, ext3]
    expect(ref[:extended].extensions.map(&:class)).to eq [ext1, ext2]
  end

  it "exclude_extensions removes all inherited extensions" do
    ext1 = Class.new(Blueprinter::Extension)

    blueprint = Class.new(Blueprinter::V2::Base) do
      add ext1.new

      view :extended do
        exclude_extensions
      end
    end

    ref = blueprint.reflections
    expect(ref[:default].extensions.map(&:class)).to eq [ext1]
    expect(ref[:extended].extensions.map(&:class)).to eq []
  end
end
