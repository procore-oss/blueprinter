require 'ostruct'
require_relative 'shared/base_render_examples'
require_relative '../rails_test_helper'
require_relative '../factories/model_factories.rb'

describe '::Base' do
  describe '::render' do
    subject { blueprint.render(obj) }

    context 'Outside Rails project' do
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
      let(:vehicle) { OpenStruct.new(id: 1, make: 'Super Car') }

      include_examples 'Base::render'
    end

    context 'Inside Rails project' do
      include FactoryGirl::Syntax::Methods
      let(:obj) { create(:user) }
      let(:vehicle) { create(:vehicle) }

      include_examples 'Base::render'
    end
  end
end
