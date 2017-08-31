FactoryGirl.define do
  factory :user do
    first_name "Meg"
    last_name  "Jones"
    email 'fake@fake.org'
    address = "123 Fake Street\n" +
      "Fakesville, OH 12345"
  end

  factory :vehicle do
    make 'Harper'
    model 'Invacar'
    miles { rand(1..500000) }
    association :user
  end
end
