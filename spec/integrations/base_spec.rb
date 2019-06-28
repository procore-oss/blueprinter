require 'activerecord_helper'
require 'ostruct'
require_relative 'shared/base_render_examples'

describe '::Base' do
  let(:blueprint_with_block) do
    Class.new(Blueprinter::Base) do
      identifier :id
      field :position_and_company do |obj|
        "#{obj.position} at #{obj.company}"
      end
    end
  end
  let(:obj_hash) do
    {
      id: 1,
      first_name: 'Meg',
      last_name: 'Ryan',
      position: 'Manager',
      description: 'A person',
      company: 'Procore',
      birthday: Date.new(1994, 3, 4),
      deleted_at: nil,
      active: false
    }
  end
  let(:object_with_attributes) { OpenStruct.new(obj_hash) }

  describe '::render' do
    subject { blueprint.render(obj) }

    context 'Outside Rails project' do
      context 'Given passed object has dot notation accessible attributes' do
        let(:obj) { object_with_attributes }
        let(:obj_id) { obj.id.to_s }
        let(:vehicle) { OpenStruct.new(id: 1, make: 'Super Car') }

        include_examples 'Base::render'
      end

      context 'Given passed object is a Hash' do
        let(:blueprint_with_block) do
          Class.new(Blueprinter::Base) do
            identifier :id
            field :position_and_company do |obj|
              "#{obj[:position]} at #{obj[:company]}"
            end
          end
        end
        let(:obj) { obj_hash }
        let(:vehicle) { { id: 1, make: 'Super Car' } }
        let(:obj_id) { obj[:id].to_s }

        include_examples 'Base::render'
      end
    end

    context 'Inside Rails project' do
      include FactoryBot::Syntax::Methods
      let(:obj) { create(:user) }
      let(:obj_id) { obj.id.to_s }
      let(:vehicle) { create(:vehicle) }

      include_examples 'Base::render'

      context 'Given blueprint has ::association' do
        let(:result) do
          '{"id":' + obj_id + ',"vehicles":[{"make":"Super Car"}]}'
        end
        let(:blueprint_without_associated_blueprint) do
          Class.new(Blueprinter::Base) do
            identifier :id
            association :vehicles
          end
        end
        before { vehicle.update(user: obj) }
        context 'Given associated blueprint is given' do
          let(:blueprint) do
            vehicle_blueprint = Class.new(Blueprinter::Base) do
              fields :make
            end
            Class.new(Blueprinter::Base) do
              identifier :id
              association :vehicles, blueprint: vehicle_blueprint
            end
          end
          it('returns json with association') { should eq(result) }
        end
        context "Given association with dynamic blueprint" do
          class UserBlueprint < Blueprinter::Base
            fields :id
          end
          class User < ActiveRecord::Base
            def blueprint
              UserBlueprint
            end
          end
          let(:blueprint) do
            Class.new(Blueprinter::Base) do
              association :user, blueprint: ->(obj) { obj.blueprint }
            end
          end
          it "should render the association with dynamic blueprint" do
            expect(JSON.parse(blueprint.render(vehicle))["user"]).to eq({"id"=>obj.id})
          end
        end
        context "Given association with dynamic view", focus: true do
          let(:blueprint) do
            class UserBlueprint < Blueprinter::Base
              fields :id
              view :custom do 
                field :description
              end
            end
            Class.new(Blueprinter::Base) do
              association :user, blueprint: UserBlueprint, view: -> (o, _) {:custom}
            end
          end
          it "should render the association with dynamic blueprint" do
            expect(JSON.parse(blueprint.render(vehicle))['user']).to eq({"id"=>obj.id, "description"=>obj.description})
          end
        end
        context 'Given block is passed' do
          let(:blueprint) do
            vehicle_blueprint = Class.new(Blueprinter::Base) do
              fields :make
            end

            Class.new(Blueprinter::Base) do
              identifier :id
              association(:automobiles, blueprint: vehicle_blueprint) { |o| o.vehicles }
            end
          end
          let(:result) do
            '{"id":' + obj_id + ',"automobiles":[{"make":"Super Car"}]}'
          end
          it('returns json with aliased association') { should eq(result) }
        end
        context 'Given no associated blueprint is given' do
          let(:blueprint) do
            Class.new(Blueprinter::Base) do
              identifier :id
              association :vehicles
            end
          end
          it { expect{subject}.to raise_error(Blueprinter::BlueprinterError) }
        end

        context 'Given an association :extractor option' do
          let(:result) { '{"id":' + obj_id + ',"vehicles":[{"make":"SUPER CAR"}]}' }
          let(:blueprint) do
            extractor = Class.new(Blueprinter::Extractor) do
              def extract(association_name, object, _local_options, _options={})
                object.send(association_name).map { |vehicle| { make: vehicle.make.upcase } }
              end
            end

            vehicle_blueprint = Class.new(Blueprinter::Base) { fields :make }

            Class.new(Blueprinter::Base) do
              field :id
              association :vehicles, blueprint: vehicle_blueprint, extractor: extractor
            end
          end
          it('returns json derived from a custom extractor') { should eq(result) }
        end
      end

      context "Given association is nil" do
        before do
          expect(vehicle).to receive(:user).and_return(nil)
        end

        context "Given global default association value is specified" do
          before { Blueprinter.configure { |config| config.association_default = "N/A" } }
          after { reset_blueprinter_config! }

          context "Given default association value is not provided" do
            let(:blueprint) do
              Class.new(Blueprinter::Base) do
                fields :make
                association :user, blueprint: Class.new(Blueprinter::Base) { identifier :id }
              end
            end

            it "should render the association using the default global association value" do
              expect(JSON.parse(blueprint.render(vehicle))["user"]).to eq("N/A")
            end
          end

          context "Given default association value is provided" do
            let(:blueprint) do
              Class.new(Blueprinter::Base) do
                fields :make
                association :user,
                  blueprint: Class.new(Blueprinter::Base) { identifier :id },
                  default: {}
              end
            end

            it "should render the default value provided for the association" do
              expect(JSON.parse(blueprint.render(vehicle))["user"]).to eq({})
            end
          end

          context "Given default association value is provided and is nil" do
            let(:blueprint) do
              Class.new(Blueprinter::Base) do
                fields :make
                association :user,
                  blueprint: Class.new(Blueprinter::Base) { identifier :id },
                  default: nil
              end
            end

            it "should render the default value provided for the association" do
              expect(JSON.parse(blueprint.render(vehicle))["user"]).to be_nil
            end
          end
        end

        context "Given global default association value is not specified" do
          context "Given default association value is not provided" do
            let(:blueprint) do
              Class.new(Blueprinter::Base) do
                fields :make
                association :user, blueprint: Class.new(Blueprinter::Base) { identifier :id }
              end
            end

            it "should render the association as nil" do
              expect(JSON.parse(blueprint.render(vehicle))["user"]).to be_nil
            end
          end

          context "Given default association value is provided" do
            let(:blueprint) do
              Class.new(Blueprinter::Base) do
                fields :make
                association :user,
                  blueprint: Class.new(Blueprinter::Base) { identifier :id },
                  default: {}
              end
            end

            it "should render the default value provided for the association" do
              expect(JSON.parse(blueprint.render(vehicle))["user"]).to eq({})
            end
          end
        end
      end
    end
  end
  describe '::render_as_hash' do
    subject { blueprint_with_block.render_as_hash(object_with_attributes) }
    context 'Outside Rails project' do
      context 'Given passed object has dot notation accessible attributes' do
        let(:obj) { object_with_attributes }
        it 'returns a hash with expected format' do
          expect(subject).to eq({ id: obj.id, position_and_company: "#{obj.position} at #{obj.company}"})
        end
      end
    end
  end

  describe '::render_as_json' do
    subject { blueprint_with_block.render_as_json(object_with_attributes) }
    context 'Outside Rails project' do
      context 'Given passed object has dot notation accessible attributes' do
        let(:obj) { object_with_attributes }
        it 'returns a hash with expected format' do
          expect(subject).to eq({ "id" => obj.id, "position_and_company" => "#{obj.position} at #{obj.company}"})
        end
      end
    end
  end

  describe 'identifier' do
    let(:rendered) do
      blueprint.render_as_hash(OpenStruct.new(uid: 42))
    end

    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :uid
      end
    end

    it "renders identifier" do
      expect(rendered).to eq(uid: 42)
    end

    describe 'Given a block is passed' do
      let(:blueprint) do
        Class.new(Blueprinter::Base) do
          identifier(:id) { |object, _| object.uid * 2 }
        end
      end

      it "renders result of block" do
        expect(rendered).to eq(id: 84)
      end
    end
  end

  describe 'Using dynamic include view' do
    let(:obj) { OpenStruct.new(id: 1, view: :custom, name: 'Meg') }
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        include_view {|o| o.view }

        view :custom do
          field :name 
        end
      end
    end
    
    subject { blueprint.render_as_hash(obj) }
    it('includes view fields') { expect(subject[:name]).to eq(obj.name) }
  end

  describe 'Using the ApplicationBlueprint pattern' do
    let(:obj) { OpenStruct.new(id: 1, name: 'Meg', age: 32) }
    let(:application_blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :name
        field(:overridable) { |o| o.name }

        view :with_age do
          field :age
        end

        view :anonymous_age do
          include_view :with_age
          exclude :name
        end
      end
    end

    let(:blueprint) do
      Class.new(application_blueprint) do
        field(:overridable) { |o| o.age }

        view :only_age do
          include_view :with_age
          exclude :name
        end
      end
    end

    subject { blueprint.render_as_hash(obj) }

    it('inherits identifier') { expect(subject[:id]).to eq(obj.id) }
    it('inherits field') { expect(subject[:name]).to eq(obj.name) }
    it('overrides field definition') { expect(subject[:overridable]).to eq(obj.age) }

    describe 'Inheriting views' do
      let(:view) { :with_age }
      subject { blueprint.render_as_hash(obj, view: view) }

      it('includes identifier') { expect(subject[:id]).to eq(obj.id) }
      it('includes base fields') { expect(subject[:name]).to eq(obj.name) }
      it('includes view fields') { expect(subject[:age]).to eq(obj.age) }

      describe 'With complex views' do
        let(:view) { :anonymous_age }

        it('includes identifier') { expect(subject[:id]).to eq(obj.id) }
        it('includes include_view fields') { expect(subject[:age]).to eq(obj.age) }
        it('excludes excluded fields') { expect(subject).to_not have_key(:name) }
      end

      describe 'Referencing views from parent blueprint' do
        let(:view) { :only_age }

        it('includes include_view fields') { expect(subject[:age]).to eq(obj.age) }
        it('excludes excluded fields') { expect(subject).not_to have_key(:name) }
      end
    end
  end
end
