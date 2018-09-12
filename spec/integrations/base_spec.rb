require 'ostruct'
require_relative 'shared/base_render_examples'
require_relative '../rails_test_helper'
require_relative '../factories/model_factories.rb'

describe '::Base' do
  let(:blueprint_with_block) do
    Class.new(Blueprinter::Base) do
      identifier :id
      field :position_and_company do |obj|
        "#{obj.position} at #{obj.company}"
      end
    end
  end
  let(:blueprint_with_mapping) do
    Class.new(Blueprinter::Base) do
      identifier :id
      field :position_and_company

      mapping do
        def position_and_company
          struct = object.is_a?(Hash) ? OpenStruct.new(object) : object
            "#{struct.position} at #{struct.company}"
        end
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
      birthday: Date.new(1994, 3, 4)
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
        context 'Given no associated blueprint is given' do
          let(:blueprint) do
            Class.new(Blueprinter::Base) do
              identifier :id
              association :vehicles
            end
          end
          it { expect{subject}.to raise_error(Blueprinter::BlueprinterError) }
        end
      end

      context "Given association is nil" do
        before do
          expect(vehicle).to receive(:user).and_return(nil)
        end

        context "Given default association value is not provided" do
          let(:blueprint) do
            vehicle_blueprint = Class.new(Blueprinter::Base) do
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
            vehicle_blueprint = Class.new(Blueprinter::Base) do
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
end
