# frozen_string_literal: true

module PerfBench
  module Blueprints
    # Blueprints for the realistic profiles. Each method defines fresh classes.
    module Profiles
      ISO = '%Y-%m-%dT%H:%M:%SZ'
      LIST = Fixtures.field_names(10).freeze

      module_function

      def part
        supplier = Class.new(Blueprinter::Base) do
          identifier :id
          fields :name, :country
        end
        Blueprints.part { association :supplier, blueprint: supplier }
      end

      # A list endpoint: mixed types, a rename, a nil-dropped field, two blocks, one option-gated field, depth 3.
      def index(&extra)
        Blueprints.widget(fields: false, part: Profiles.part) do
          fields(*LIST, :status, :price)
          field :f12, name: :code
          field :released_on, datetime_format: DATE_FORMAT
          field :created_at, datetime_format: ISO
          field :description, exclude_if_nil: true
          field(:label) { |w, _opts| "#{w.f00} (#{w.status})" }
          field(:price_cents, if: ->(_name, _w, opts) { opts[:show_prices] }) { |w, _opts| (w.price * 100).to_i }
          class_eval(&extra) if extra
        end
      end

      def order
        company = Blueprints.company
        user = Class.new(Blueprinter::Base) do
          identifier :id
          fields :name, :email
          association :company, blueprint: company
        end
        part = Profiles.part
        line_item = Class.new(Blueprinter::Base) do
          identifier :id
          fields :quantity, :unit_price
          field(:subtotal) { |li, _opts| li.unit_price * li.quantity }
          association :part, blueprint: part
        end
        Class.new(Blueprinter::Base) do
          identifier :id
          fields :number, :status, :total
          field :placed_at, datetime_format: TIME_FORMAT
          field :note, exclude_if_nil: true
          association :user, blueprint: user
          association :line_items, blueprint: line_item
        end
      end
    end
  end

  sweep 'profiles', 'Realistic profiles',
        'Composite scenarios combining many axes. ActiveRecord inputs are loaded fresh for every render with ' \
        'associations preloaded.' do
    options = { show_prices: true, current_user_id: 7, locale: 'en' }
    widgets = -> { Records.widgets(50, includes: [:company, { parts: :supplier }]) }

    scenario 'AR list: 50 widgets to JSON, depth 3', fresh_input: true,
                                                     note: 'Mixed types (BigDecimal, Date, Time formatted), rename, ' \
                                                           'exclude_if_nil, 2 blocks, option-gated field, ' \
                                                           'parts -> supplier.' do
      Setup.new(input: widgets, engines: PerfBench.json_engines(Blueprints::Profiles.index, options:))
    end

    scenario 'AR detail: 1 widget, extended view, to JSON', fresh_input: true,
                                                            note: 'The extended view includes a summary view.' do
      summary = Fixtures.field_names(25).drop(13).first(5)
      extended = Fixtures.field_names(25).drop(18)
      blueprint = Blueprints::Profiles.index do
        view(:summary) { fields(*summary) }
        view(:extended) do
          include_view :summary
          fields(*extended)
        end
      end
      Setup.new(input: -> { widgets.call.first },
                engines: [engine { |input| blueprint.render(input, options.merge(view: :extended)) }])
    end

    scenario 'AR orders: 100 orders to a Hash, depth 4', fresh_input: true,
                                                         note: 'order -> user -> company, order -> line items -> ' \
                                                               'part -> supplier; BigDecimal, formatted Time, a block.' do
      Setup.new(input: -> { Records.orders(100) }, engines: PerfBench.hash_engines(Blueprints::Profiles.order))
    end

    scenario 'Hash export: 5,000 rows, 12 fields, no associations' do
      blueprint = Blueprints.widget(width: 10, company: nil, part: nil) do
        field(:summary) { |w, _opts| "#{w[:f00]}/#{w[:f01]}" }
        field(:odd) { |w, _opts| w[:f01].odd? }
      end
      Setup.new(input: -> { Fixtures.widgets(5_000, width: 10, parts: nil, company: false) },
                engines: PerfBench.hash_engines(blueprint))
    end

    scenario 'Options-heavy: plain objects, rename, if, default_if, association options, transformer' do
      input = lambda do
        list = Fixtures.widgets(BASELINE_SIZE)
        list.each { |w| w[:f12] = +'' if (w[:id] % 3).zero? }
        Fixtures.convert(list, :poro)
      end
      company = Blueprints.company { field(:label) { |_obj, opts| opts[:label] } }
      blueprint = Blueprints.widget(width: 10, company: nil) do
        field :f10, name: :title
        field :f11, if: ->(_name, w, _opts) { w.id.odd? }
        field :f12, default: 'n/a', default_if: Blueprinter::EMPTY_STRING
        association :company, blueprint: company, options: { label: 'from parent' }
        transform Blueprints::KindTransformer
      end
      Setup.new(input:, engines: PerfBench.hash_engines(blueprint))
    end

    scenario 'Instrumented AR list: 50 widgets to JSON, pre_render + transformer', fresh_input: true,
                                                                                   config: lambda { |c|
                                                                                     c.extensions << Blueprints::NoopPreRender.new
                                                                                   } do
      blueprint = Blueprints::Profiles.index { transform Blueprints::KindTransformer }
      Setup.new(input: widgets, engines: PerfBench.json_engines(blueprint, options:))
    end
  end
end
