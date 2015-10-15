FactoryGirl.define do
  factory :user do
    username "bobby_tables"
    password "bobby tables's very secure password"
    display_name "Bobby Tables"
    bio "Wherever I went, computers disliked me :("
    email "bobby@tables-family.com"
    email_confirm "bobby@tables-family.com"

    after(:create) do |user|
      user.tags << FactoryGirl.create(:tag, user: user)
    end

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

    factory :administrator_user do
      username "admin_bobby"
      password "admin bobby tables's very secure password"
      display_name "Administrator Bobby"
      bio "Wherever I went, computers disliked me, now I manage them :D"
      email "admin_bobby@tables-family.com"
      email_confirm "admin_bobby@tables-family.com"
      role_id 1
    end
  end


end
