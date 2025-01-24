FactoryBot.define do
  factory :subscription do
    factory :calling_subscription do
      slug { 'kg' }
      name { 'Kooragang' }
    end
  end
end
