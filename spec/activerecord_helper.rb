require 'active_record'
require 'factories/model_factories.rb'

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:",
)

class Vehicle < ActiveRecord::Base
  belongs_to :user
end

class User < ActiveRecord::Base
  attr_accessor :company, :description, :position
  has_many :vehicles
end

ActiveRecord::Schema.define(version: 20170830212110) do
  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.text "address"
    t.datetime "birthday"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
