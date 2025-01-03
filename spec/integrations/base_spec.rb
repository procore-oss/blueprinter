# frozen_string_literal: true

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
      active: false,
      dynamic_fields: {"full_name" => "Meg Ryan"}
    }
  end
  let(:object_with_attributes) { OpenStruct.new(obj_hash) }

  describe '::render' do
    subject { blueprint.render(obj) }

    context 'when providing a view' do
      let(:blueprint) do
        Class.new(Blueprinter::Base) do
          identifier :id
          field :first_name

          view :extended do
            field :last_name
          end
        end
      end
      it 'renders the data based on the view definition' do
        expect(blueprint.render(object_with_attributes, view: :extended)).
          to eq('{"id":1,"first_name":"Meg","last_name":"Ryan"}')
      end
      context 'and the value is nil' do
        it 'falls back to the :default view' do
          expect(blueprint.render(object_with_attributes, view: nil)).
            to eq(blueprint.render(object_with_attributes))
        end
      end
    end

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

    context 'Given passed object is array-like' do
      let(:blueprint) { blueprint_with_block }
      let(:additional_object) { OpenStruct.new(obj_hash.merge(id: 2)) }
      let(:obj) { Set.new([object_with_attributes, additional_object]) }

      context 'and is an instance of a configured array-like class' do
        before do
          reset_blueprinter_config!
          Blueprinter.configure { |config| config.custom_array_like_classes = [Set] }
        end
        after { reset_blueprinter_config! }

        it 'should return the expected array of hashes' do
          should eq('[{"id":1,"position_and_company":"Manager at Procore"},{"id":2,"position_and_company":"Manager at Procore"}]')
        end
      end

      context 'and is not an instance of a configured array-like class' do
        it 'should raise an error' do
          expect { blueprint.render(obj) }.to raise_error(NoMethodError)
        end
      end
    end

    context 'Given exclude_if_nil is passed' do
      let(:obj) { OpenStruct.new(obj_hash.merge(category: nil, label: 'not nil')) }

      context 'and exclude_if_nil is true' do
        let(:blueprint) do
          Class.new(Blueprinter::Base) do
            field :category, exclude_if_nil: true
            field :label, exclude_if_nil: true
          end
        end
        let(:result) { '{"label":"not nil"}' }
        it { expect(blueprint.render(obj)).to eq(result) }
      end

      context 'and exclude_if_nil is false' do
        let(:blueprint) do
          Class.new(Blueprinter::Base) do
            field :category, exclude_if_nil: false
            field :label, exclude_if_nil: true
          end
        end
        let(:result) { '{"category":null,"label":"not nil"}' }
        it { expect(blueprint.render(obj)).to eq(result) }
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
        context 'Given associated blueprint does not inherit from Blueprinter::Base' do
          let(:blueprint) do
            vehicle_invalid_blueprint = Class.new
            Class.new(Blueprinter::Base) do
              identifier :id
              association :vehicles, blueprint: vehicle_invalid_blueprint
            end
          end
          it { expect { subject }.to raise_error(Blueprinter::Errors::InvalidBlueprint) }
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
        context "Given default_if option is Blueprinter::EMPTY_HASH" do
          before do
            expect(vehicle).to receive(:user).and_return({})
          end

          context "Given a default value" do
            let(:blueprint) do
              Class.new(Blueprinter::Base) do
                association :user,
                  blueprint: Class.new(Blueprinter::Base) { identifier :id },
                  default: "empty_hash",
                  default_if: Blueprinter::EMPTY_HASH
              end
            end
            it('uses the correct default value') do
              expect(JSON.parse(blueprint.render(vehicle))["user"]).to eq("empty_hash")
            end
          end

          context "Given no default value" do
            let(:blueprint) do
              Class.new(Blueprinter::Base) do
                association :user,
                  blueprint: Class.new(Blueprinter::Base) { identifier :id },
                  default_if: Blueprinter::EMPTY_HASH
              end
            end
            it('uses the correct default value') do
              expect(JSON.parse(blueprint.render(vehicle))["user"]).to eq(nil)
            end
          end
        end
        context "Given default_if option is Blueprinter::EMPTY_COLLECTION" do
          before { vehicle.update(user: nil) }
          after { vehicle.update(user: obj) }

          context "Given a default value" do
            let(:result) do
              '{"id":' + obj_id + ',"vehicles":"foo"}'
            end
            let(:blueprint) do
              vehicle_blueprint = Class.new(Blueprinter::Base) {}
              Class.new(Blueprinter::Base) do
                identifier :id
                association :vehicles, blueprint: vehicle_blueprint, default: "foo", default_if: Blueprinter::EMPTY_COLLECTION
              end
            end
            it('returns json with association') { should eq(result) }
          end

          context "Given no default value" do
            let(:result) do
              '{"id":' + obj_id + ',"vehicles":null}'
            end
            let(:blueprint) do
              vehicle_blueprint = Class.new(Blueprinter::Base) {}
              Class.new(Blueprinter::Base) do
                identifier :id
                association :vehicles, blueprint: vehicle_blueprint, default_if: Blueprinter::EMPTY_COLLECTION
              end
            end
            it('returns json with association') { should eq(result) }
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
          it 'raises an ArgumentError' do
            expect { subject }.
              to raise_error(ArgumentError, /:blueprint must be provided when defining an association/)
          end
        end
        context 'Given an association :options option' do
          let(:result) { '{"id":' + obj_id + ',"vehicles":[{"make":"Super Car Enhanced"}]}' }
          let(:blueprint) do
            vehicle_blueprint = Class.new(Blueprinter::Base) do
              field :make do |vehicle, options|
                "#{vehicle.make} #{options[:modifier]}"
              end
            end

            Class.new(Blueprinter::Base) do
              field :id
              association :vehicles, blueprint: vehicle_blueprint, options: { modifier: 'Enhanced' }
            end
          end
          it('returns json using the association options') { should eq(result) }
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
        context 'when a view is specified' do
          let(:vehicle) { create(:vehicle, :with_model) }
          let(:blueprint) do
            vehicle_blueprint = Class.new(Blueprinter::Base) do
              fields :make

              view :with_model do
                field :model
              end
            end
            Class.new(Blueprinter::Base) do
              identifier :id
              association :vehicles, blueprint: vehicle_blueprint, view: :with_model
            end
          end
          let(:result) do
            "{\"id\":#{obj.id},\"vehicles\":[{\"make\":\"Super Car\",\"model\":\"ACME\"}]}"
          end
          it 'leverages the specified view when rendering the association' do
            expect(blueprint.render(obj)).to eq(result)
          end
        end
        context 'Given included view with re-defined association' do
          let(:blueprint) do
            vehicle_blueprint = Class.new(Blueprinter::Base) do
              fields :make

              view :with_size do
                field :size do 10 end
              end

              view :with_height do
                field :height do 2 end
              end
            end
            Class.new(Blueprinter::Base) do
              identifier :id
              association :vehicles, blueprint: vehicle_blueprint

              view :with_size do
                association :vehicles, blueprint: vehicle_blueprint, view: :with_size
              end

              view :with_height do
                include_view :with_size
                association :vehicles, blueprint: vehicle_blueprint, view: :with_height
              end
            end
          end

          let(:result_default) do
            '{"id":' + obj_id + ',"vehicles":[{"make":"Super Car"}]}'
          end
          let(:result_with_size) do
            '{"id":' + obj_id + ',"vehicles":[{"make":"Super Car","size":10}]}'
          end
          let(:result_with_height) do
            '{"id":' + obj_id + ',"vehicles":[{"height":2,"make":"Super Car"}]}'
          end

          it 'returns json with association' do
            expect(blueprint.render(obj)).to eq(result)
            expect(blueprint.render(obj, view: :with_size)).to eq(result_with_size)
            expect(blueprint.render(obj, view: :with_height)).to eq(result_with_height)
          end
        end
        context 'when if option is provided' do
          let(:vehicle) { create(:vehicle, make: 'Super Car') }
          let(:user_without_cars) { create(:user, vehicles: []) }
          let(:user_with_cars) { create(:user, vehicles: [vehicle]) }

          let(:blueprint) do
            vehicle_blueprint = Class.new(Blueprinter::Base) do
              fields :make
            end
            Class.new(Blueprinter::Base) do
              identifier :id
              association :vehicles, blueprint: vehicle_blueprint, if: ->(_field_name, object, _local_opts) { object.vehicles.present? }
            end
          end
          it 'does not render the association if the if condition is not met' do
            expect(blueprint.render(user_without_cars)).to eq("{\"id\":#{user_without_cars.id}}")
          end
          it 'renders the association if the if condition is met' do
            expect(blueprint.render(user_with_cars)).to eq("{\"id\":#{user_with_cars.id},\"vehicles\":[{\"make\":\"Super Car\"}]}")
          end

          context 'and if option is a symbol' do
            let(:blueprint) do
              vehicle_blueprint = Class.new(Blueprinter::Base) do
                fields :make
              end
              Class.new(Blueprinter::Base) do
                identifier :id
                association :vehicles, blueprint: vehicle_blueprint, if: :has_vehicles?
                association :vehicles, name: :cars, blueprint: vehicle_blueprint, if: :has_cars?

                def self.has_vehicles?(_field_name, object, local_options)
                  false
                end

                def self.has_cars?(_field_name, object, local_options)
                  true
                end
              end
            end

            it 'renders the association based on evaluating the symbol as a method on the blueprint' do
              expect(blueprint.render(user_with_cars)).
                to eq("{\"id\":#{user_with_cars.id},\"cars\":[{\"make\":\"Super Car\"}]}")
            end
          end
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

      context 'Given passed object is an instance of a configured array-like class' do
        let(:blueprint) do
          Class.new(Blueprinter::Base) do
            identifier :id
            fields :make
          end
        end
        let(:vehicle1) { build(:vehicle, id: 1) }
        let(:vehicle2) { build(:vehicle, id: 2, make: 'Mediocre Car') }
        let(:vehicle3) { build(:vehicle, id: 3, make: 'Terrible Car') }
        let(:vehicles) { [vehicle1, vehicle2, vehicle3] }
        let(:obj) { Set.new(vehicles) }
        let(:result) do
          vehicles_json = vehicles.map do |vehicle|
            "{\"id\":#{vehicle.id},\"make\":\"#{vehicle.make}\"}"
          end.join(',')
          "[#{vehicles_json}]"
        end

        before do
          reset_blueprinter_config!
          Blueprinter.configure do |config|
            config.custom_array_like_classes = [Set]
          end
        end
        after { reset_blueprinter_config! }

        it('returns the expected result') { should eq(result) }

        context 'Given options containing `view` and rendered multiple times (as in batching)' do
          let(:blueprint) do
            Class.new(Blueprinter::Base) do
              field :id
              view :with_make do
                field :make
              end
            end
          end

          let(:options) { { view: :with_make } }

          subject do
            obj.map do |vehicle|
              blueprint.render_as_hash(vehicle, options)
            end.to_json
          end

          it('returns the expected result') { should eq(result) }
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

  describe 'has_view?' do
    subject { blueprint.view?(view) }

    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :uid
        view :custom do
        end
      end
    end

    context 'when the blueprint has the supplied view' do
      let(:view) { :custom }
      it { is_expected.to eq(true) }
    end

    context 'when the blueprint does not have the supplied view' do
      let(:view) { :does_not_exist }
      it { is_expected.to eq(false) }
    end
  end

  describe 'Using the ApplicationBlueprint pattern' do
    let(:obj) { OpenStruct.new(id: 1, first_name: 'Meg',last_name:'Ryan', age: 32) }
    let(:transformer) do
      Class.new(Blueprinter::Transformer) do
        def transform(result_hash, object, options={})
         result_hash.merge!({full_name: "#{object.first_name} #{object.last_name}"})
        end
      end
    end
    let(:application_blueprint) do
      custom_transformer = transformer
      Class.new(Blueprinter::Base) do
        identifier :id
        field :first_name
        field(:overridable) { |o| o.name }

        view :with_age do
          field :age
          transform custom_transformer
        end

        view :anonymous_age do
          include_view :with_age
          exclude :first_name
        end
      end
    end

    let(:blueprint) do
      Class.new(application_blueprint) do
        field(:overridable) { |o| o.age }

        view :only_age do
          include_view :with_age
          exclude :first_name
        end

        view :with_age do
          field :last_name
        end
      end
    end

    subject { blueprint.render_as_hash(obj) }

    it('inherits identifier') { expect(subject[:id]).to eq(obj.id) }
    it('inherits field') { expect(subject[:first_name]).to eq(obj.first_name) }
    it('overrides field definition') { expect(subject[:overridable]).to eq(obj.age) }

    describe 'Inheriting views' do
      let(:view) { :with_age }
      subject { blueprint.render_as_hash(obj, view: view) }

      it('includes identifier') { expect(subject[:id]).to eq(obj.id) }
      it('includes base fields') { expect(subject[:first_name]).to eq(obj.first_name) }
      it('includes view fields') { expect(subject[:age]).to eq(obj.age) }
      it('inherits base fields') { expect(subject[:last_name]).to eq(obj.last_name) }
      it('inherits transformer fields') { expect(subject[:full_name]).to eq("#{obj.first_name} #{obj.last_name}") }

      describe 'With complex views' do
        let(:view) { :anonymous_age }

        it('includes identifier') { expect(subject[:id]).to eq(obj.id) }
        it('includes include_view fields') { expect(subject[:age]).to eq(obj.age) }
        it('excludes excluded fields') { expect(subject).to_not have_key(:first_name) }
      end

      describe 'Referencing views from parent blueprint' do
        let(:view) { :only_age }

        it('includes include_view fields') { expect(subject[:age]).to eq(obj.age) }
        it('excludes excluded fields') { expect(subject).not_to have_key(:first_name) }
      end
    end
  end
end
