# frozen_string_literal: true

describe "Blueprinter::V2 Names" do
  context 'const named Blueprints' do
    class NamedBlueprint < Blueprinter::V2
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
      Class.new(Blueprinter::V2) do
        self.blueprint_name = "MyBlueprint"
        view :extended
      end
    end

    it 'should have no base name' do
      expect(blueprint.to_s).to eq "MyBlueprint"
      expect(blueprint.inspect).to eq "MyBlueprint"
      expect(blueprint.view_name).to eq :default
    end

    it 'should find a view by name' do
      expect(blueprint[:extended].to_s).to eq "MyBlueprint.extended"
      expect(blueprint[:extended].inspect).to eq "MyBlueprint.extended"
      expect(blueprint[:extended].view_name).to eq :extended
    end
  end

  context 'anonymous Blueprints' do
    let(:blueprint) do
      Class.new(Blueprinter::V2) do
        view :extended
      end
    end

    it 'should have no base name' do
      expect(blueprint.blueprint_name).to eq "Blueprinter::V2"
      expect(blueprint.view_name).to eq :default
    end

    it 'should find a view by name' do
      expect(blueprint[:extended].blueprint_name).to eq "Blueprinter::V2.extended"
      expect(blueprint[:extended].view_name).to eq :extended
    end
  end

  context 'deeply nested Blueprints' do
    let(:blueprint) do
      Class.new(Blueprinter::V2) do
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
    blueprint = Class.new(Blueprinter::V2)
    expect { blueprint.view :"foo.bar" }.to raise_error(
      Blueprinter::Errors::InvalidBlueprint,
      /name may not contain/
    )
  end
end
