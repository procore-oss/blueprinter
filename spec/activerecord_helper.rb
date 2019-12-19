require 'active_record'
require 'factories/model_factories.rb'

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:",
)

class Vehicle < ActiveRecord::Base
  belongs_to :user
end

module Electric # must move above require 'factories/model_factories.rb' to enable a factory
  class Truck < ::Vehicle
  end
end

class User < ActiveRecord::Base
  attr_accessor :company, :description, :position, :active
  has_many :vehicles

  def dynamic_fields
    {"full_name" => "#{first_name} #{last_name}"}
  end
end

ActiveRecord::Schema.define(version: 20181116094242) do
  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.text "address"
    t.datetime "birthday"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.boolean "active"
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "make"
    t.string "model"
    t.integer "miles"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_vehicles_on_user_id"
  end
end

ActiveRecord::Migration.maintain_test_schema!
