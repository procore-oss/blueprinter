FactoryBot.define do
  factory :user do
    first_name 'Meg'
    last_name  'Jones'
    position 'Manager'
    description 'A person'
    company 'Procore'
  end

  factory :vehicle do
    make 'Super Car'
    association :user
  end
end
