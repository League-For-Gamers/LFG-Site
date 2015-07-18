class Ban < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
  belongs_to :role

  validates :user, :role, presence: true
  validates :reason, length: { maximum: 1024 }
end
