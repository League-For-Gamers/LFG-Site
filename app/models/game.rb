class Game < ActiveRecord::Base
  include Postable

  has_and_belongs_to_many :users
  validates :name, presence: true, uniqueness: {case_sensitive: false}

  before_validation do
    remove_zalgo! self.name
  end
end
