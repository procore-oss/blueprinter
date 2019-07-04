require 'factory_bot'

FactoryBot.define do
  factory :user do
    first_name { 'Meg' }
    last_name  { 'Ryan' }
    position { 'Manager' }
    description { 'A person' }
    company { 'Procore' }
    birthday { Date.new(1994, 3, 4) }
    deleted_at { nil }
    active { false }
  end

  factory :vehicle do
    make { 'Super Car' }
    association :user
  end
end
