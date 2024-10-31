# frozen_string_literal: true

describe "Blueprinter::V2 Names" do
  context 'const named Blueprints' do
    class NamedBlueprint < Blueprinter::V2::Base
      view :extended
    end

    it 'should have a base name' do
      expect(NamedBlueprint.to_s).to eq "NamedBlueprint"
      expect(NamedBlueprint.inspect).to eq "NamedBlueprint"
      expect(NamedBlueprint.blueprint_name).to eq "NamedBlueprint"
      expect(NamedBlueprint.view_name).to eq :default
    end

    it 'should find a view by name' do
      expect(NamedBlueprint[:extended].to_s).to eq "NamedBlueprint.extended"
      expect(NamedBlueprint[:extended].inspect).to eq "NamedBlueprint.extended"
      expect(NamedBlueprint[:extended].blueprint_name).to eq "NamedBlueprint.extended"
      expect(NamedBlueprint[:extended].view_name).to eq :extended
    end

    it 'should raise for an invalid view name' do
      expect { NamedBlueprint[:wrong_name] }.to raise_error(
        Blueprinter::Errors::UnknownView,
        "View 'wrong_name' could not be found in Blueprint 'NamedBlueprint'"
      )
    end
  end

  context 'manually named Blueprints' do
    let(:blueprint) do
      Class.new(Blueprinter::V2::Base) do
        self.blueprint_name = "MyBlueprint"
        view :extended
      end
    end

    it 'should have no base name' do
      expect(blueprint.to_s).to eq "MyBlueprint"
      expect(blueprint.inspect).to eq "MyBlueprint"
    end

    it 'should find a view by name' do
      expect(blueprint[:extended].to_s).to eq "MyBlueprint.extended"
      expect(blueprint[:extended].inspect).to eq "MyBlueprint.extended"
    end
  end

  context 'anonymous Blueprints' do
    let(:blueprint) do
      Class.new(Blueprinter::V2::Base) do
        view :extended
      end
    end

    it 'should have no base name' do
      expect(blueprint.blueprint_name).to eq "Blueprinter::V2::Base"
      expect(blueprint.view_name).to eq :default
    end

    it 'should find a view by name' do
      expect(blueprint[:extended].blueprint_name).to eq "Blueprinter::V2::Base.extended"
      expect(blueprint[:extended].view_name).to eq :extended
    end
  end

  context 'deeply nested Blueprints' do
    let(:blueprint) do
      Class.new(Blueprinter::V2::Base) do
        self.blueprint_name = "MyBlueprint"

        view :foo do
          view :bar do
            view :zorp
          end
        end
      end
    end

    it 'should find deeply nested names' do
      expect(blueprint.blueprint_name).to eq "MyBlueprint"
      expect(blueprint.view_name).to eq :default

      expect(blueprint[:foo].blueprint_name).to eq "MyBlueprint.foo"
      expect(blueprint[:foo].view_name).to eq :foo

      expect(blueprint[:foo][:bar].blueprint_name).to eq "MyBlueprint.foo.bar"
      expect(blueprint[:foo][:bar].view_name).to eq :"foo.bar"

      expect(blueprint[:foo][:bar][:zorp].blueprint_name).to eq "MyBlueprint.foo.bar.zorp"
      expect(blueprint[:foo][:bar][:zorp].view_name).to eq :"foo.bar.zorp"
    end

    it 'should find deeply nested names using dot syntax' do
      expect(blueprint["foo"].blueprint_name).to eq "MyBlueprint.foo"
      expect(blueprint["foo"].view_name).to eq :foo

      expect(blueprint["foo.bar"].blueprint_name).to eq "MyBlueprint.foo.bar"
      expect(blueprint["foo.bar"].view_name).to eq :"foo.bar"

      expect(blueprint["foo.bar.zorp"].blueprint_name).to eq "MyBlueprint.foo.bar.zorp"
      expect(blueprint["foo.bar.zorp"].view_name).to eq :"foo.bar.zorp"
    end
  end

  it "should not contain periods" do
    blueprint = Class.new(Blueprinter::V2::Base)
    expect { blueprint.view :"foo.bar" }.to raise_error(
      Blueprinter::Errors::InvalidBlueprint,
      /name may not contain/
    )
  end

  it 'should have the current view name accessible from within the DSL' do
    default_name = nil
    foo_name = nil
    foo_bar_name = nil

    bp = Class.new(Blueprinter::V2::Base) do
      default_name = view_name
      view :foo do
        foo_name = view_name
        view :bar do
          foo_bar_name = view_name
        end
      end
    end

    bp[:default]
    bp[:foo]
    bp[:"foo.bar"]

    expect(default_name).to eq :default
    expect(foo_name).to eq :foo
    expect(foo_bar_name).to eq :"foo.bar"
  end
end
