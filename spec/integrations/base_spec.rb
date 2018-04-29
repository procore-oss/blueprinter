require 'ostruct'
require_relative 'shared/base_render_examples'
require_relative '../rails_test_helper'
require_relative '../factories/model_factories.rb'

describe '::Base' do
  describe '::render' do
    subject { blueprint.render(obj) }
    let(:blueprint_with_block) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :position_and_company do |obj|
          "#{obj.position} at #{obj.company}"
        end
      end
    end

    context 'Outside Rails project' do
      context 'Given passed object has dot notation accessible attributes' do
        let(:obj_hash) do
          {
            id: 1,
            first_name: 'Meg',
            last_name: 'Ryan',
            position: 'Manager',
            description: 'A person',
            company: 'Procore'
          }
        end
        let(:obj) { OpenStruct.new(obj_hash) }
        let(:obj_id) { obj.id.to_s }
        let(:vehicle) { OpenStruct.new(id: 1, make: 'Super Car') }

        include_examples 'Base::render'
      end

      context 'Given passed object is a Hash' do
        let(:obj) do
          {
            id: 1,
            first_name: 'Meg',
            last_name: 'Ryan',
            position: 'Manager',
            description: 'A person',
            company: 'Procore'
          }
        end
        let(:vehicle) { { id: 1, make: 'Super Car' } }
        let(:obj_id) { obj[:id].to_s }
        let(:blueprint_with_block) do
          Class.new(Blueprinter::Base) do
            identifier :id
            field :position_and_company do |obj|
              "#{obj[:position]} at #{obj[:company]}"
            end
          end
        end

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
    end
  end
end
