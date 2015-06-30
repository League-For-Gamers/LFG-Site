FactoryGirl.define do
  factory :skill do
    category :code
    confidence {rand(1..10)}
    user
  end

end
