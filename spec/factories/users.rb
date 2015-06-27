FactoryGirl.define do
  factory :user do
    username "bobby_tables"
    password "bobby tables's very secure password"
    display_name "Bobby Tables"
    bio "Wherever I went, computers disliked me :("
    email "bobby@tables-family.com"

    factory :user_with_skill do
      after(:create) do |user|
        create(:skill, user: user)
      end
    end

    factory :user_with_game do
      after(:create) do |user|
        user.games << FactoryGirl.create(:game)
      end
    end
  end

end
