class Follow < ApplicationRecord
  belongs_to :user
  belongs_to :following, :class_name => 'User'

  # User can only follow someone once
  validates_uniqueness_of :following_id, scope: :user_id
end
