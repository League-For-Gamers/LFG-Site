class Skill < ActiveRecord::Base
  enum category: [:writing, :design, :sound, :art, :code]
  belongs_to :user

  validates :category, :user, presence: true
  validates :confidence, inclusion: { in:  1..10}
  validates_uniqueness_of :category, scope: :user_id
end
