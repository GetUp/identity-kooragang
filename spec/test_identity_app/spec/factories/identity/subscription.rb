FactoryBot.define do
  factory :subscription do
    factory :calling_subscription do
      slug { 'calling' }
      name { 'Calling' }
    end
  end
end
