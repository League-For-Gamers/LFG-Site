FactoryGirl.define do
  factory :group do
    title "League for Gamers"
    privacy :public_group
    post_control :public_posts
    comment_privacy :public_comments
    membership :public_membership
  end
end
