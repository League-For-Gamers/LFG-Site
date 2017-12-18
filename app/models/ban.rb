class Ban < ApplicationRecord
  belongs_to :user
  belongs_to :post, required: false
  belongs_to :role, required: false
  belongs_to :group, required: false
  belongs_to :banner, class_name: 'User', foreign_key: 'banner_id', required: false

  validates :user, :banner, presence: true
  validates :reason, length: { maximum: 1024 }

  # At least one needs to be filled.
  validates :role, presence: true, unless: ->(ban){ban.group_role.present?}
  validates :group_role, presence: true, unless: ->(ban){ban.role.present?}
end
