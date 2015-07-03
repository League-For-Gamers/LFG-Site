FactoryGirl.define do
  factory :tag do
    sequence(:name) { |n| "VidyaGame_#{n}" }
    user
  end

end
