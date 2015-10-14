class Group < ActiveRecord::Base
  # Public and private cannot be used for method names as they as reserved
  enum privacy: [:public_group, :manangement_only_post, :members_only_post, :private_group]
  enum comment_privacy: [:public_comments, :members_only_comment, :private_comments]
  enum membership: [:public_membership, :owner_verified, :invite_only]

  has_many :group_memberships
  has_many :users, through: :group_memberships
  has_many :posts
end
