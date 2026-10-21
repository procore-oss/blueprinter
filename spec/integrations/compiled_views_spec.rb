# frozen_string_literal: true

require 'activerecord_helper'

# Renders the same blueprints with compile_views off and on and checks that the output is identical.
describe 'Compiled views' do
  include FactoryBot::Syntax::Methods

  before { reset_blueprinter_config! }
  after { reset_blueprinter_config! }

  # Records every pre_render call so both modes can be compared
  let(:extension_log) { [] }
  let(:logging_extension) do
    log = extension_log
    Class.new(Blueprinter::Extension) do
      define_method(:pre_render) do |object, blueprint, view, options|
        log << [object.class.name, blueprint, view, options.keys.sort]
        object
      end
    end.new
  end

  def key_orders(result)
    case result
    when Array then result.map { |item| key_orders(item) }
    when Hash then result.map { |key, value| [key, key_orders(value)] }
    else result
    end
  end

  def render_with(compile_views, blueprint, object, options)
    Blueprinter.configuration.compile_views = compile_views
    extension_log.clear
    hash = blueprint.render_as_hash(object, options)
    json = blueprint.render(object, options)
    [hash, json, extension_log.dup]
  end

  def expect_same_output(blueprint, object, options = {})
    standard = render_with(false, blueprint, object, options)
    compiled = render_with(true, blueprint, object, options)

    expect(compiled[0]).to eq(standard[0])
    expect(key_orders(compiled[0])).to eq(key_orders(standard[0]))
    expect(compiled[1]).to eq(standard[1])
    expect(compiled[2]).to eq(standard[2])
    # Compiled views are skipped while these global settings are set
    config = Blueprinter.configuration
    return unless [config.datetime_format, config.field_default, config.association_default, config.if, config.unless].all?(&:nil?)

    expect(blueprint.send(:view_collection).instance_variable_get(:@cache)[:compiled]).not_to be_empty
  end

  let(:user) { create(:user, vehicles: [create(:vehicle, :with_model), create(:vehicle, miles: 10)]) }
  let(:user_without_vehicles) { create(:user, first_name: '', last_name: nil) }
  let(:objects) do
    {
      'a record' => user,
      'a record without associations' => user_without_vehicles,
      'an Array' => [user, user_without_vehicles],
      'an ActiveRecord::Relation' => User.where(id: [user.id, user_without_vehicles.id]).order(:id),
      'an empty Array' => []
    }
  end

  let(:vehicle_blueprint) do
    Class.new(Blueprinter::Base) do
      identifier :id
      fields :make, :model

      view :extended do
        field :miles
        field(:seen_view) { |_vehicle, options| options[:view] }
      end
    end
  end

  shared_examples 'the same output' do |option_sets|
    option_sets.each do |options|
      it "renders the same output with options #{options.inspect}", :aggregate_failures do
        objects.each_value { |object| expect_same_output(blueprint, object, options) }
      end
    end
  end

  context 'with fields and views' do
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        fields :first_name, :last_name
        field :position, name: :job_title

        view :normal do
          fields :company, :description
        end

        view :extended do
          include_view :normal
          exclude :last_name
          field :birthday
        end
      end
    end

    include_examples 'the same output', [{}, { view: :normal }, { view: :extended }, { view: :identifier },
                                         { view: :extended, root: :user, meta: { page: 1 } }]
  end

  context 'with conditions and exclude_if_nil' do
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :first_name, if: ->(_name, user, _options) { user.first_name.present? }
        field :last_name, exclude_if_nil: true
        field :company, unless: ->(_name, _user, options) { options[:hide_company] }
        field :position, if: :show_position?
        field :description, if: ->(*) { true }, unless: :hide_description?

        def self.show_position?(_name, _user, options) = options[:show_position]
        def self.hide_description?(name, _user, options) = options[:hidden]&.include?(name)
      end
    end

    include_examples 'the same output', [{}, { hide_company: true }, { show_position: true, hidden: [:description] }]
  end

  context 'with blocks' do
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field(:full_name) { |user, options| "#{options[:prefix]}#{user.first_name} #{user.last_name}" }
        field :upcased_name, &->(user, _options) { user.first_name.to_s.upcase }
        field :first_name, name: :symbol_proc, &:first_name
        field(:keywords) { |user, view:, **| "#{user.id}@#{view}" }
      end
    end

    include_examples 'the same output', [{}, { prefix: 'Dr. ' }]
  end

  context 'with defaults' do
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :last_name, default: 'N/A'
        field :first_name, default: 'blank', default_if: Blueprinter::EMPTY_STRING
        field :missing_hash, default: { a: 1 }, default_if: Blueprinter::EMPTY_HASH do |_user, _options|
          {}
        end
        field :missing_list, default: [0], default_if: Blueprinter::EMPTY_COLLECTION do |_user, _options|
          []
        end
        field :unknown_empty_type, default: 'never', default_if: 'not_a_type' do |_user, _options|
          nil
        end
        association :vehicles, blueprint: Class.new(Blueprinter::Base) { identifier :id },
                               default: 'no vehicles', default_if: Blueprinter::EMPTY_COLLECTION
      end
    end

    include_examples 'the same output', [{}]

    context 'when field_default is configured' do
      before { Blueprinter.configure { |config| config.field_default = 'field default' } }

      let(:blueprint) do
        Class.new(Blueprinter::Base) do
          identifier :id
          fields :last_name, :deleted_at
          association :vehicles, blueprint: Class.new(Blueprinter::Base) { identifier :id }, default_if: Blueprinter::EMPTY_COLLECTION
        end
      end

      include_examples 'the same output', [{}]

      it 'applies it to nil association values too, in both modes' do
        nil_association = Class.new(Blueprinter::Base) do
          association :nothing, blueprint: Class.new(Blueprinter::Base) { identifier :id } do |_user, _options|
            nil
          end
        end

        [false, true].each do |compile_views|
          Blueprinter.configuration.compile_views = compile_views
          expect { nil_association.render_as_hash(user) }.to raise_error(NoMethodError, /id/)
        end
      end
    end

    context 'when association_default is configured' do
      before { Blueprinter.configure { |config| config.association_default = 'association default' } }

      let(:blueprint) do
        Class.new(Blueprinter::Base) do
          identifier :id
          association :vehicles, blueprint: Class.new(Blueprinter::Base) { identifier :id }, default_if: Blueprinter::EMPTY_COLLECTION
          association :nothing, blueprint: Class.new(Blueprinter::Base) { identifier :id } do |_user, _options|
            nil
          end
        end
      end

      include_examples 'the same output', [{}]
    end
  end

  context 'with datetime formats' do
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :birthday, datetime_format: '%Y/%m/%d'
        field :created_at, datetime_format: ->(time) { time.to_i }
        field :updated_at
        field :first_name
      end
    end

    include_examples 'the same output', [{}]

    context 'when datetime_format is configured globally' do
      before { Blueprinter.configure { |config| config.datetime_format = '%d-%m-%Y' } }

      include_examples 'the same output', [{}]
    end

    it 'raises the same error for an invalid format' do
      invalid = Class.new(Blueprinter::Base) { field :first_name, datetime_format: '%Y' }

      [false, true].each do |compile_views|
        Blueprinter.configuration.compile_views = compile_views
        expect { invalid.render_as_hash(user) }.to raise_error(Blueprinter::DateTimeFormatter::InvalidDateTimeFormatterError)
      end
    end
  end

  context 'with global if/unless' do
    before do
      Blueprinter.configure do |config|
        config.if = ->(name, _object, options) { !options[:skip]&.include?(name) }
        config.unless = ->(name, _object, _options) { name == :description }
      end
    end

    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        fields :first_name, :last_name, :description
        field :company, if: ->(*) { true }
      end
    end

    include_examples 'the same output', [{}, { skip: %i[last_name company] }]
  end

  context 'with associations' do
    let(:blueprint) do
      vehicles = vehicle_blueprint
      Class.new(Blueprinter::Base) do
        identifier :id
        field :first_name
        association :vehicles, blueprint: vehicles
        association :first_vehicle, blueprint: vehicles, view: :extended, exclude_if_nil: true do |user, _options|
          user.vehicles.min_by(&:id)
        end
        association :vehicles, name: :conditional_vehicles, blueprint: vehicles,
                               if: ->(_name, _user, options) { options[:with_vehicles] }

        view :extended do
          association :vehicles, blueprint: vehicles, view: :extended
        end
      end
    end

    before { Blueprinter.configure { |config| config.extensions << logging_extension } }

    include_examples 'the same output', [{}, { with_vehicles: true }, { view: :extended, with_vehicles: true }]
  end

  context 'with associations that use the standard code path' do
    let(:blueprint) do
      vehicles = vehicle_blueprint
      Class.new(Blueprinter::Base) do
        identifier :id
        association :vehicles, name: :dynamic, blueprint: ->(_vehicles) { vehicles }
        association :vehicles, name: :with_static_options, blueprint: vehicles, view: :extended, options: { extra: 1 }
        association :vehicles, name: :with_dynamic_options, blueprint: vehicles,
                               options: ->(user) { { owner: user.first_name } }
      end
    end

    before { Blueprinter.configure { |config| config.extensions << logging_extension } }

    include_examples 'the same output', [{}]
  end

  context 'with a custom extractor' do
    let(:upcase_extractor) do
      Class.new(Blueprinter::Extractor) do
        def extract(field_name, object, _local_options, _options = {})
          object.public_send(field_name).to_s.upcase
        end
      end
    end

    let(:blueprint) do
      extractor = upcase_extractor
      Class.new(Blueprinter::Base) do
        identifier :id
        field :first_name, extractor: extractor
        field :last_name, extractor: Class.new(Blueprinter::AutoExtractor).new
        field :company
      end
    end

    include_examples 'the same output', [{}]
  end

  context 'with transformers' do
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :first_name
        transform(Class.new(Blueprinter::Transformer) do
          def transform(hash, object, options)
            hash[:transformed] = "#{object.id}-#{options[:view]}"
          end
        end)

        view :extended do
          field :last_name
          transform(Class.new(Blueprinter::Transformer) do
            def transform(hash, _object, _options)
              hash.delete(:first_name)
            end
          end)
        end
      end
    end

    include_examples 'the same output', [{}, { view: :extended }]
  end

  context 'with Hash objects and unusual names' do
    let(:blueprint) do
      vehicles = vehicle_blueprint
      Class.new(Blueprinter::Base) do
        identifier :id
        field :first_name
        field :'kebab-name', name: :'Kebab Name'
        association :vehicles, blueprint: vehicles
      end
    end
    let(:objects) do
      {
        'a Hash' => { id: 1, first_name: 'Meg', 'kebab-name': 'k', vehicles: [{ id: 2, make: 'A', model: 'B' }] },
        'a mixed Array' => [{ id: 1, first_name: 'Meg', vehicles: nil }, Struct.new(:id, :first_name, :'kebab-name', :vehicles).new(2, 'Ann', 'x', [])]
      }
    end

    include_examples 'the same output', [{}]
  end

  context 'with fields sorted by definition' do
    before { Blueprinter.configure { |config| config.sort_fields_by = :definition } }

    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        field :last_name
        identifier :id
        field :first_name

        view :normal do
          field :company
        end

        view :extended do
          field :position
          include_view :normal
        end
      end
    end

    include_examples 'the same output', [{}, { view: :extended }]
  end

  context 'with inheritance and an identifier redefined as a field' do
    let(:blueprint) do
      parent = Class.new(Blueprinter::Base) do
        identifier :id
        field :id, name: :id
        field :first_name
      end
      Class.new(parent) { field :last_name }
    end

    include_examples 'the same output', [{}]
  end

  it 'raises the same error for an unknown association view' do
    vehicles = vehicle_blueprint
    broken = Class.new(Blueprinter::Base) { association :vehicles, blueprint: vehicles, view: :missing }
    nil_broken = Class.new(Blueprinter::Base) do
      association(:nothing, blueprint: vehicles, view: :missing) { |_user, _options| nil }
    end

    [false, true].each do |compile_views|
      Blueprinter.configuration.compile_views = compile_views
      expect { broken.render_as_hash(user) }.to raise_error(Blueprinter::Errors::UnknownView, "View 'missing' is not defined")
      expect(nil_broken.render_as_hash(user)).to eq(nothing: nil)
    end
  end
end
