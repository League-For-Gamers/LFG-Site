class Game < ActiveRecord::Base
  has_and_belongs_to_many :users
  validates :name, presence: true, uniqueness: {case_sensitive: false}
end
