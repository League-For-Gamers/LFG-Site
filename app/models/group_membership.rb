class GroupMembership < ActiveRecord::Base
  belongs_to :group
  belongs_to :user

  enum role: [:owner, :moderator, :member, :banned]

  validates :role, presence: true
end
