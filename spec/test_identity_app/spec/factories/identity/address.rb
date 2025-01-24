FactoryBot.define do
  factory :address do
    line1 { Faker::Address.street_address }
    town { Faker::Address.city }
    state { Faker::Address.state_abbr }
    postcode { Faker::Address.zip_code }
  end
end
