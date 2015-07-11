class Skill < ActiveRecord::Base
  enum category: [:game_programming, :web_programming, :html, :graphic_design, :'2d_art', :'3d_art', :animation, :production,
                  :writing, :community, :music, :sound_effects, :'pr_&_marketting', :biz_dev]
  belongs_to :user

  validates :category, :user, presence: true
  validates :confidence, inclusion: {in:  1..10}
  validates :note, length: {maximum: 65}
  validates_uniqueness_of :category, scope: :user_id
end
