# frozen_string_literal: true

module EngineBench
  module Blueprints
    # Blueprints for the realistic profiles. Each method defines fresh classes.
    module Profiles
      ISO = '%Y-%m-%dT%H:%M:%SZ'
      LIST = Fixtures.field_names(10).freeze

      module_function

      def v1_part
        supplier = Class.new(Blueprinter::Base) do
          identifier :id
          fields :name, :country
        end
        Blueprints::V1.part { association :supplier, blueprint: supplier }
      end

      def v2_part(app)
        return unless EngineBench.v2?

        supplier = Class.new(app) do
          self.blueprint_name = 'SupplierBlueprint'
          fields :id, :name, :country
        end
        Blueprints::V2.part(app) { association :supplier, supplier }
      end

      def v2_formats
        proc do
          format(Date) { |d| d.strftime(DATE_FORMAT) }
          format(Time) { |t| t.strftime(ISO) }
        end
      end

      # A list endpoint: mixed types, a rename, a nil-dropped field, two blocks, one option-gated field, depth 3.
      def index_v1(&extra)
        Blueprints::V1.widget(fields: false, part: v1_part) do
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

      def index_v2(app = Blueprints::V2.app(&v2_formats), &extra)
        return unless EngineBench.v2?

        Blueprints::V2.widget(app, fields: false, part: v2_part(app)) do
          fields(*LIST, :status, :price)
          field :code, source: :f12
          fields :released_on, :created_at
          field :description, exclude_if_nil: true
          field(:label) { |w| "#{w.f00} (#{w.status})" }
          field(:price_cents, if: ->(ctx) { ctx.options[:show_prices] }) { |w| (w.price * 100).to_i }
          class_eval(&extra) if extra
        end
      end

      def index_legacy(app = Blueprints::V2.app(&v2_formats), &extra)
        return unless EngineBench.v2?

        app.add Blueprinter::Extensions::LegacyOptions.new
        Blueprints::V2.widget(app, fields: false, part: v2_part(app)) do
          fields(*LIST, :status, :price)
          field :f12, name: :code
          fields :released_on, :created_at
          field :description, exclude_if_nil: true
          field(:label) { |w, _ctx| "#{w.f00} (#{w.status})" }
          field(:price_cents, if: ->(_name, _w, opts) { opts[:show_prices] }) { |w| (w.price * 100).to_i }
          class_eval(&extra) if extra
        end
      end

      def order_v1
        company = Blueprints::V1.company
        user = Class.new(Blueprinter::Base) do
          identifier :id
          fields :name, :email
          association :company, blueprint: company
        end
        part = v1_part
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

      def order_v2
        return unless EngineBench.v2?

        app = Blueprints::V2.app { format(Time) { |t| t.strftime(TIME_FORMAT) } }
        company = Blueprints::V2.company(app)
        user = Class.new(app) do
          fields :id, :name, :email
          association :company, company
        end
        part = v2_part(app)
        line_item = Class.new(app) do
          fields :id, :quantity, :unit_price
          field(:subtotal) { |li| li.unit_price * li.quantity }
          association :part, part
        end
        Class.new(app) do
          self.blueprint_name = 'OrderBlueprint'
          fields :id, :number, :status, :total, :placed_at
          field :note, exclude_if_nil: true
          association :user, user
          association :line_items, [line_item]
        end
      end
    end
  end

  sweep 'profiles', 'Realistic profiles',
        'Composite scenarios combining many axes. ActiveRecord inputs are loaded fresh for every render with ' \
        'associations preloaded. V2+Legacy runs where V1-style options are involved.',
        engines: LEGACY_ENGINES do
    options = { show_prices: true, current_user_id: 7, locale: 'en' }

    scenario 'AR list: 50 widgets to JSON, depth 3', fresh_input: true,
                                                     note: 'Mixed types (BigDecimal, Date, Time formatted), rename, ' \
                                                           'exclude_if_nil, 2 blocks, option-gated field, ' \
                                                           'parts -> supplier.' do
      Setup.new(input: -> { Records.widgets(50, includes: [:company, { parts: :supplier }]) },
                engines: EngineBench.json_engines(Blueprints::Profiles.index_v1, Blueprints::Profiles.index_v2,
                                                  Blueprints::Profiles.index_legacy, options:))
    end

    scenario 'AR detail: 1 widget, extended view, to JSON', fresh_input: true,
                                                            note: 'V1 `include_view`, V2 `use` of the view as a ' \
                                                                  'partial, V2+Legacy `view:`.' do
      summary = Fixtures.field_names(25).drop(13).first(5)
      extended = Fixtures.field_names(25).drop(18)
      v1 = Blueprints::Profiles.index_v1 do
        view(:summary) { fields(*summary) }
        view(:extended) do
          include_view :summary
          fields(*extended)
        end
      end
      views = proc do
        view(:summary) { fields(*summary) }
        view(:extended) do
          use :summary
          fields(*extended)
        end
      end
      v2 = Blueprints::Profiles.index_v2(&views)
      legacy = Blueprints::Profiles.index_legacy(&views)
      Setup.new(input: -> { Records.widgets(1, includes: [:company, { parts: :supplier }]).first }, engines: [
        engine('V1') { |input| v1.render(input, options.merge(view: :extended)) },
        engine('V2') { |input| v2[:extended].render(input, options).to_json },
        engine('V2+Legacy') { |input| legacy.render(input, options.merge(view: :extended)).to_json }
      ])
    end

    scenario 'AR orders: 100 orders to a Hash, depth 4', fresh_input: true,
                                                         note: 'order -> user -> company, order -> line items -> ' \
                                                               'part -> supplier; BigDecimal, formatted Time, a block.' do
      Setup.new(input: -> { Records.orders(100) },
                engines: EngineBench.hash_engines(Blueprints::Profiles.order_v1, Blueprints::Profiles.order_v2))
    end

    scenario 'Hash export: 5,000 rows, 12 fields, no associations' do
      v1 = Blueprints::V1.widget(width: 10, company: nil, part: nil) do
        field(:summary) { |w, _opts| "#{w[:f00]}/#{w[:f01]}" }
        field(:odd) { |w, _opts| w[:f01].odd? }
      end
      v2 = Blueprints::V2.widget(width: 10, company: nil, part: nil) do
        field(:summary) { |w| "#{w[:f00]}/#{w[:f01]}" }
        field(:odd) { |w| w[:f01].odd? }
      end
      Setup.new(input: -> { Fixtures.widgets(5_000, width: 10, parts: nil, company: false) },
                engines: EngineBench.hash_engines(v1, v2))
    end

    scenario 'Migrating app: plain objects, V1-style options',
             note: 'Rename, 3-argument `if`, `default_if: EMPTY_STRING`, association `:options`, a transformer. V2 ' \
                   'passes the association option as a render option and adds the key with an extension.' do
      input = lambda do
        list = Fixtures.widgets(BASELINE_SIZE)
        list.each { |w| w[:f12] = +'' if (w[:id] % 3).zero? }
        Fixtures.convert(list, :poro)
      end
      assoc_options = { label: 'from parent' }
      v1_company = Blueprints::V1.company { field(:label) { |_obj, opts| opts[:label] } }
      v1 = Blueprints::V1.widget(width: 10, company: nil) do
        field :f10, name: :title
        field :f11, if: ->(_name, w, _opts) { w.id.odd? }
        field :f12, default: 'n/a', default_if: Blueprinter::EMPTY_STRING
        association :company, blueprint: v1_company, options: assoc_options
        transform Blueprints::KindTransformer
      end
      app = Blueprints::V2.app
      v2_company = Blueprints::V2.company(app) { field(:label) { |_obj, ctx| ctx.options[:label] } }
      v2 = Blueprints::V2.widget(app, width: 10, company: v2_company) do
        field :title, source: :f10
        field :f11, if: ->(ctx) { ctx.object.id.odd? }
        field :f12, default: 'n/a', default_if: ->(_ctx, v) { v.to_s.empty? }
        add Blueprints::KindExtension.new
      end
      legacy_app = Blueprints::V2.app { add Blueprinter::Extensions::LegacyOptions.new }
      legacy_company = Blueprints::V2.company(legacy_app) { field(:label) { |_obj, ctx| ctx.options[:label] } }
      legacy = Blueprints::V2.widget(legacy_app, width: 10, company: nil) do
        add Blueprinter::Extensions::LegacyDynamicOptions.new
        add Blueprinter::Extensions::LegacyTransformer.new(Blueprints::KindTransformer)
        field :f10, name: :title
        field :f11, if: ->(_name, w, _opts) { w.id.odd? }
        field :f12, default: 'n/a', default_if: Blueprinter::EMPTY_STRING
        association :company, legacy_company, options: assoc_options
      end
      Setup.new(input:, engines: [
        engine('V1') { |list| v1.render_as_hash(list) },
        engine('V2') { |list| v2.render(list, assoc_options).to_hash },
        engine('V2+Legacy') { |list| legacy.render(list).to_hash }
      ])
    end

    instrumented_note = 'V1: a pre_render extension and a transformer. V2: the OpenTelemetry extension (no-op ' \
                        'tracer) and an around_blueprint extension. V2+Legacy: OpenTelemetry and LegacyTransformer.'
    unless EngineBench.feature?(:opentelemetry) || !EngineBench.v2?
      instrumented_note += ' V2 columns omitted: the opentelemetry-api gem is not installed.'
    end
    scenario 'Instrumented AR list: 50 widgets to JSON, tracing + transformer',
             fresh_input: true, note: instrumented_note,
             v1_config: ->(c) { c.extensions << Blueprints::NoopPreRender.new } do
      v1 = Blueprints::Profiles.index_v1 { transform Blueprints::KindTransformer }
      v2 = legacy = nil
      if EngineBench.feature?(:opentelemetry)
        otel = -> { Blueprinter::Extensions::OpenTelemetry.new('engine-bench') }
        v2_app = Blueprints::V2.app(&Blueprints::Profiles.v2_formats)
        v2_app&.add otel.call
        v2 = Blueprints::Profiles.index_v2(v2_app) { add Blueprints::KindExtension.new }
        legacy_app = Blueprints::V2.app(&Blueprints::Profiles.v2_formats)
        legacy_app&.add otel.call
        legacy = Blueprints::Profiles.index_legacy(legacy_app) do
          add Blueprinter::Extensions::LegacyTransformer.new(Blueprints::KindTransformer)
        end
      end
      Setup.new(input: -> { Records.widgets(50, includes: [:company, { parts: :supplier }]) },
                engines: EngineBench.json_engines(v1, v2, legacy, options:))
    end
  end
end
