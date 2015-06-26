FactoryGirl.define do
  factory :game do
    sequence(:name) { |n| "Call of Duty #{n}" }
  end
end
