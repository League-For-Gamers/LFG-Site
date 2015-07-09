class Skill < ActiveRecord::Base
  enum category: {writing: 0, design: 1, sound: 2, art: 3, programming: 4}
  belongs_to :user

  validates :category, :user, presence: true
  validates :confidence, inclusion: { in:  1..10}
  validates :note, length: {maximum: 65}
  validates_uniqueness_of :category, scope: :user_id
end
