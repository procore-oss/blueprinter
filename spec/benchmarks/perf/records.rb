# frozen_string_literal: true

require 'active_record'
require_relative 'fixtures'

module PerfBench
  # In-memory SQLite models for ActiveRecord inputs. Loaded on first use; seeded once per process.
  module Records
    WIDGETS = 1_000
    WIDGET_WIDTH = 50
    COMPANIES = 20
    SUPPLIERS = 10
    USERS = 50
    ORDERS = 200
    LINE_ITEMS_PER_ORDER = 5

    class Record < ActiveRecord::Base
      self.abstract_class = true
    end

    class Company < Record
      has_many :widgets
      has_many :users
    end

    class Supplier < Record
      has_many :parts
    end

    class Widget < Record
      belongs_to :company
      has_many :parts, -> { order(:id) }
    end

    class Part < Record
      belongs_to :widget
      belongs_to :supplier
    end

    class User < Record
      belongs_to :company
      has_many :orders, -> { order(:id) }
    end

    class Order < Record
      belongs_to :user
      has_many :line_items, -> { order(:id) }
    end

    class LineItem < Record
      belongs_to :order
      belongs_to :part
    end

    class << self
      def setup!
        return if @_setup

        Record.establish_connection(adapter: 'sqlite3', database: ':memory:')
        ActiveRecord::Base.logger = nil
        ActiveRecord::Migration.verbose = false
        define_schema!
        seed!
        @_setup = true
      end

      # Freshly loaded widgets with their associations preloaded, so rendering issues no queries.
      def widgets(count, includes: %i[company parts])
        setup!
        Widget.includes(*includes).order(:id).limit(count).to_a
      end

      def orders(count)
        setup!
        Order.includes(user: :company, line_items: { part: :supplier }).order(:id).limit(count).to_a
      end

      # @return [Integer] SQL queries issued while the block runs
      def count_queries(&)
        count = 0
        counter = ->(*, payload) { count += 1 unless payload[:name] == 'SCHEMA' }
        ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &)
        count
      end

      private

      # rubocop:disable Metrics/MethodLength
      def define_schema!
        conn = Record.connection
        conn.create_table(:companies) do |t|
          t.string :name
          t.string :city
        end
        conn.create_table(:suppliers) do |t|
          t.string :name
          t.string :country
        end
        conn.create_table(:widgets) do |t|
          t.integer :company_id
          Fixtures.field_names(WIDGET_WIDTH).each_with_index do |name, i|
            i.even? ? t.string(name) : t.integer(name)
          end
          t.string :status
          t.text :description
          t.decimal :price, precision: 10, scale: 2
          t.date :released_on
          t.datetime :created_at
          t.datetime :updated_at
        end
        conn.create_table(:parts) do |t|
          t.integer :widget_id
          t.integer :supplier_id
          t.string :name
          t.integer :number
        end
        conn.create_table(:users) do |t|
          t.integer :company_id
          t.string :name
          t.string :email
          t.datetime :created_at
        end
        conn.create_table(:orders) do |t|
          t.integer :user_id
          t.string :number
          t.string :status
          t.decimal :total, precision: 10, scale: 2
          t.datetime :placed_at
          t.string :note
        end
        conn.create_table(:line_items) do |t|
          t.integer :order_id
          t.integer :part_id
          t.integer :quantity
          t.decimal :unit_price, precision: 10, scale: 2
        end
      end

      def seed!
        Company.insert_all!(Array.new(COMPANIES) { |i| Fixtures.company(i + 1) })
        Supplier.insert_all!(Array.new(SUPPLIERS) { |i| { id: i + 1, name: "Supplier #{i + 1}", country: "C#{i % 3}" } })
        Widget.insert_all!(Array.new(WIDGETS) { |i| widget_row(i + 1) })
        Part.insert_all!(
          (1..WIDGETS).flat_map do |n|
            Array.new(3) { |i| Fixtures.part(n, i + 1).merge(widget_id: n, supplier_id: ((n + i) % SUPPLIERS) + 1) }
          end
        )
        User.insert_all!(Array.new(USERS) { |i| user_row(i + 1) })
        Order.insert_all!(Array.new(ORDERS) { |i| order_row(i + 1) })
        LineItem.insert_all!(
          (1..ORDERS).flat_map do |n|
            Array.new(LINE_ITEMS_PER_ORDER) do |i|
              widget = (((n * 7) + i) % WIDGETS) + 1
              { id: (n * 10) + i, order_id: n, part_id: (widget * 1000) + (i % 3) + 1, quantity: i + 1,
                unit_price: BigDecimal("#{n % 90}.#{(i * 11) % 100}") }
            end
          end
        )
      end
      # rubocop:enable Metrics/MethodLength

      def widget_row(n)
        Fixtures.attributes(n, width: WIDGET_WIDTH).merge(
          id: n, company_id: ((n - 1) % COMPANIES) + 1, status: n.even? ? 'active' : 'retired',
          description: (n % 3).zero? ? nil : "Widget number #{n}", price: BigDecimal("#{n}.#{n % 100}"),
          released_on: Fixtures::BASE_DATE + n, created_at: Fixtures::BASE_TIME + n,
          updated_at: Fixtures::BASE_TIME + (n * 2)
        )
      end

      def user_row(n)
        { id: n, company_id: ((n - 1) % COMPANIES) + 1, name: "User #{n}", email: "user#{n}@example.com",
          created_at: Fixtures::BASE_TIME + n }
      end

      def order_row(n)
        { id: n, user_id: ((n - 1) % USERS) + 1, number: "ORD-#{n.to_s.rjust(5, '0')}", status: %w[open paid shipped][n % 3],
          total: BigDecimal("#{n * 3}.#{n % 100}"), placed_at: Fixtures::BASE_TIME + (n * 60), note: n.even? ? nil : 'Gift' }
      end
    end
  end
end
