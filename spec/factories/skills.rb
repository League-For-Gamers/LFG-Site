FactoryGirl.define do
  factory :skill do
    category :writing
    confidence {rand(1..10)}
    user
  end

end
