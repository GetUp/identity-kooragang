FactoryBot.define do
  factory :member do
    name { Faker::Name.name_with_middle }
    email { Faker::Internet.email }

    factory :member_with_mobile do
      after(:create) do |member, evaluator|
        create(:mobile_number, member: member)
      end

      factory :member_with_mobile_and_custom_fields do
        after(:create) do |member, evaluator|
          create(:custom_field, member: member, custom_field_key: FactoryBot.create(:custom_field_key))
        end
      end
    end

    factory :member_without_email do
      email { nil }
    end

    factory :member_with_landline do
      after(:create) do |member, evaluator|
        create(:landline_number, member: member)
      end
    end

    factory :member_with_address do
      after(:create) do |member, evaluator|
        create(:address, member: member)
      end
    end

    factory :member_with_the_lot do
      after(:create) do |member, evaluator|
        create(:mobile_number, member: member)
        create(:landline_number, member: member)
        create(:address, member: member)
        create(:custom_field, member: member, custom_field_key: FactoryBot.create(:custom_field_key))
      end
    end
  end
end
